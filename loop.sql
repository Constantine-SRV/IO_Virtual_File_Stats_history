--use db with tbl_IO_Virtual_File_Stats
DECLARE @maxTbSizeMb INT = 100;      -- Maximum allowed size in MB before cleanup

DECLARE @waitForTime NVARCHAR(8);    -- Variable to store the next execution time
DECLARE @msgTxt NVARCHAR(100);       -- Variable to store the message text
DECLARE @tbSize BIGINT;              -- Variable to store the table size in MB

WHILE 1 = 1
BEGIN
    -- Calculate the next full minute
    SET @waitForTime = CONVERT(CHAR(8), DATEADD(SECOND, 60 - DATEPART(SECOND, GETDATE()), GETDATE()), 108);
    
    -- Form the message to notify about the next execution
    SET @msgTxt = 'Next execution at: ' + @waitForTime;
    
    -- Print the message immediately
    RAISERROR(@msgTxt, 0, 1) WITH NOWAIT;
    
    -- Wait until the next full minute
    WAITFOR TIME @waitForTime;

    -- Insert the data into the table
    INSERT INTO tbl_IO_Virtual_File_Stats (database_id, file_id, sample_ms, num_of_reads, num_of_bytes_read, io_stall_read_ms,
                                           num_of_writes, num_of_bytes_written, io_stall_write_ms, io_stall,
                                           io_stall_queued_read_ms, io_stall_queued_write_ms)
    SELECT 
        database_id,
        file_id,
        sample_ms,
        num_of_reads,
        num_of_bytes_read,
        io_stall_read_ms,
        num_of_writes,
        num_of_bytes_written,
        io_stall_write_ms,
        io_stall,
        io_stall_queued_read_ms,
        io_stall_queued_write_ms
    FROM sys.dm_io_virtual_file_stats(NULL, NULL);

    -- Calculate the current table size in MB
    SELECT @tbSize = SUM(reserved_page_count) * 8 / 1024
    FROM sys.dm_db_partition_stats
    WHERE object_id = OBJECT_ID('tbl_IO_Virtual_File_Stats');
    
    -- Check if the table size exceeds the maximum allowed size
    IF @tbSize > @maxTbSizeMb
    BEGIN
        -- Delete 10% of the oldest records
        DELETE TOP (10) PERCENT FROM tbl_IO_Virtual_File_Stats;  -- if only one index

        -- Notify about the deletion
        SET @msgTxt = '!----- Deleted top 10prc of records --------- ' + CAST(@@ROWCOUNT AS NVARCHAR) + '  records at ' + CONVERT(VARCHAR(5), GETDATE(), 108);
        RAISERROR(@msgTxt, 0, 1) WITH NOWAIT;
        
        -- Rebuild the primary key index after deletion
        ALTER INDEX [PK_tbl_IO_Virtual_File_Stats] ON [dbo].[tbl_IO_Virtual_File_Stats]
        REBUILD PARTITION = ALL WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON);
    END;
END;
