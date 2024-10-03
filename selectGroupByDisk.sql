WITH FileStatsWithLag AS (
    SELECT
        vfs.RecordID,
        vfs.database_id,
        vfs.file_id,
        vfs.sample_ms,
        vfs.num_of_reads,
        vfs.num_of_writes,
        vfs.num_of_bytes_read,
        vfs.num_of_bytes_written,
        vfs.io_stall_read_ms,
        vfs.io_stall_write_ms,
        vfs.io_stall,
        vfs.dt,
        mf.physical_name,
        DB_NAME(vfs.database_id) AS db_name,
        LEFT(mf.physical_name, 1) AS DriveLetter,
        
        LAG(vfs.num_of_reads) OVER (PARTITION BY vfs.database_id, vfs.file_id ORDER BY vfs.dt) AS prev_num_of_reads,
        LAG(vfs.num_of_writes) OVER (PARTITION BY vfs.database_id, vfs.file_id ORDER BY vfs.dt) AS prev_num_of_writes,
        LAG(vfs.num_of_bytes_read) OVER (PARTITION BY vfs.database_id, vfs.file_id ORDER BY vfs.dt) AS prev_num_of_bytes_read,
        LAG(vfs.num_of_bytes_written) OVER (PARTITION BY vfs.database_id, vfs.file_id ORDER BY vfs.dt) AS prev_num_of_bytes_written,
        LAG(vfs.io_stall_read_ms) OVER (PARTITION BY vfs.database_id, vfs.file_id ORDER BY vfs.dt) AS prev_io_stall_read_ms,
        LAG(vfs.io_stall_write_ms) OVER (PARTITION BY vfs.database_id, vfs.file_id ORDER BY vfs.dt) AS prev_io_stall_write_ms,
        LAG(vfs.io_stall) OVER (PARTITION BY vfs.database_id, vfs.file_id ORDER BY vfs.dt) AS prev_io_stall
    FROM tbl_IO_Virtual_File_Stats vfs
    JOIN sys.master_files mf
        ON vfs.database_id = mf.database_id
        AND vfs.file_id = mf.file_id
)
SELECT
    DriveLetter AS [Drive],
    dt,
    
    SUM(num_of_reads - prev_num_of_reads) AS [Reads per Minute],
    SUM(num_of_writes - prev_num_of_writes) AS [Writes per Minute],
    
    CAST(SUM(num_of_bytes_read - prev_num_of_bytes_read) / (1024.0 * 1024.0) AS NUMERIC(12,2)) AS [Total Bytes Read per Minute (MB)],
    CAST(SUM(num_of_bytes_written - prev_num_of_bytes_written) / (1024.0 * 1024.0) AS NUMERIC(12,2)) AS [Total Bytes Written per Minute (MB)],
    
    CAST(SUM(num_of_bytes_read - prev_num_of_bytes_read) / (60.0 * 1024.0 * 1024.0) AS NUMERIC(12,2)) AS [Read Throughput (MB/s)],
    CAST(SUM(num_of_bytes_written - prev_num_of_bytes_written) / (60.0 * 1024.0 * 1024.0) AS NUMERIC(12,2)) AS [Write Throughput (MB/s)],
    
    IIF(SUM(num_of_reads - prev_num_of_reads) = 0, 0, 
	SUM(io_stall_read_ms - prev_io_stall_read_ms) / SUM(num_of_reads - prev_num_of_reads)) AS [Avg Read Latency (ms)],
    
    IIF(SUM(num_of_writes - prev_num_of_writes) = 0, 0, 
	SUM(io_stall_write_ms - prev_io_stall_write_ms) / SUM(num_of_writes - prev_num_of_writes)) AS [Avg Write Latency (ms)],
    
    IIF(SUM((num_of_reads - prev_num_of_reads) + (num_of_writes - prev_num_of_writes)) = 0, 0, 
	SUM(io_stall - prev_io_stall) / SUM((num_of_reads - prev_num_of_reads) + (num_of_writes - prev_num_of_writes))) AS [Avg Overall Latency (ms)]
    
FROM FileStatsWithLag
WHERE prev_num_of_reads IS NOT NULL
  AND prev_num_of_writes IS NOT NULL
GROUP BY DriveLetter, dt
--HAVING IIF(SUM((num_of_reads - prev_num_of_reads) + (num_of_writes - prev_num_of_writes)) = 0, 0, SUM(io_stall - prev_io_stall) / SUM((num_of_reads - prev_num_of_reads) + (num_of_writes - prev_num_of_writes))) > 0
ORDER BY dt DESC, DriveLetter;
