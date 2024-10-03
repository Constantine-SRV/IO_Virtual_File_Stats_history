USE [adminTools] -- or use master


GO

CREATE TABLE [dbo].[tbl_IO_Virtual_File_Stats](
	[RecordID] [int] IDENTITY(1,1) NOT NULL,
	[database_id] [smallint] NULL,
	[file_id] [smallint] NULL,
	[sample_ms] [bigint] NULL,
	[num_of_reads] [bigint] NULL,
	[num_of_bytes_read] [bigint] NULL,
	[io_stall_read_ms] [bigint] NULL,
	[num_of_writes] [bigint] NULL,
	[num_of_bytes_written] [bigint] NULL,
	[io_stall_write_ms] [bigint] NULL,
	[io_stall] [bigint] NULL,
	[io_stall_queued_read_ms] [bigint] NULL,
	[io_stall_queued_write_ms] [bigint] NULL,
	[dt] [smalldatetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[RecordID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[tbl_IO_Virtual_File_Stats] ADD  DEFAULT (getdate()) FOR [dt]
GO

