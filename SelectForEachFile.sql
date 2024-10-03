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
        
        -- Lag functions to get previous row values based on database_id and file_id
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
    --database_id,
  --  file_id,
    db_name AS [Database Name],
    physical_name AS [File Path],
    dt,
    
    -- Calculate the deltas for each metric and assign dimension
    CASE 
        WHEN (num_of_reads - prev_num_of_reads) = 0 THEN 0 
        ELSE (io_stall_read_ms - prev_io_stall_read_ms) / (num_of_reads - prev_num_of_reads) 
    END AS [Read Latency (ms)],
    
    CASE 
        WHEN (num_of_writes - prev_num_of_writes) = 0 THEN 0 
        ELSE (io_stall_write_ms - prev_io_stall_write_ms) / (num_of_writes - prev_num_of_writes) 
    END AS [Write Latency (ms)],
    
    CASE 
        WHEN (num_of_reads - prev_num_of_reads) + (num_of_writes - prev_num_of_writes) = 0 THEN 0 
        ELSE (io_stall - prev_io_stall) / ((num_of_reads - prev_num_of_reads) + (num_of_writes - prev_num_of_writes)) 
    END AS [Overall Latency (ms)],
    
    CASE 
        WHEN (num_of_reads - prev_num_of_reads) = 0 THEN 0 
        ELSE (num_of_bytes_read - prev_num_of_bytes_read) / (num_of_reads - prev_num_of_reads) 
    END AS [Avg Bytes per Read (bytes)],
    
    CASE 
        WHEN (num_of_writes - prev_num_of_writes) = 0 THEN 0 
        ELSE (num_of_bytes_written - prev_num_of_bytes_written) / (num_of_writes - prev_num_of_writes) 
    END AS [Avg Bytes per Write (bytes)],
    
    CASE 
        WHEN (num_of_reads - prev_num_of_reads) + (num_of_writes - prev_num_of_writes) = 0 THEN 0 
        ELSE ((num_of_bytes_read - prev_num_of_bytes_read) + (num_of_bytes_written - prev_num_of_bytes_written)) /
             ((num_of_reads - prev_num_of_reads) + (num_of_writes - prev_num_of_writes)) 
    END AS [Avg Bytes per Transfer (bytes)],
    
    -- Metrics over the last minute
    (num_of_reads - prev_num_of_reads) AS [Reads per Minute],
    (num_of_writes - prev_num_of_writes) AS [Writes per Minute],
    
    -- Conversion to MB/s (bytes to megabytes)
    CAST((num_of_bytes_read - prev_num_of_bytes_read) / (60.0 * 1024.0 * 1024.0) AS NUMERIC(12,2)) AS [Bytes Read per Second (MB/s)],
    CAST((num_of_bytes_written - prev_num_of_bytes_written) / (60.0 * 1024.0 * 1024.0) AS NUMERIC(12,2)) AS [Bytes Written per Second (MB/s)]
    
FROM FileStatsWithLag
WHERE prev_num_of_reads IS NOT NULL
  AND prev_num_of_writes IS NOT NULL
ORDER BY RecordID DESC;
