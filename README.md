
# SQL Server I/O Performance Monitoring

## Overview

This project is designed to monitor SQL Server disk I/O performance at the file level and provide detailed statistics on read/write operations and latency. It collects data every minute using the `sys.dm_io_virtual_file_stats` function and stores it in a custom table. The data is then processed using SQL queries to provide insights into disk performance, including latency, throughput, and total bytes read/written per minute.

## Features

- **Real-Time I/O Monitoring**: Collects and stores data on SQL Server I/O performance every minute, including reads, writes, and latency.
- **Historical Data Storage**: Saves the collected data in a custom table for long-term analysis and comparison.
- **Detailed Performance Metrics**: Calculates read and write latency, throughput (MB/s), and average bytes per transfer using the latest data.
- **Grouping by File and Drive**: Provides aggregated statistics for both individual database files and overall disk drives.
- **Automatic Data Cleanup**: Includes logic to periodically delete old data to prevent the table from growing too large.
- **Support for Multiple Disks**: Groups data by the first letter of the file path to analyze performance at the disk level.

## Key Queries

### 1. **Disk-Level Performance Query**
Use this query to get a high-level overview of performance, focusing on disk-level metrics like read/write throughput, total bytes, and latency per disk. This is useful for identifying overall disk load and potential bottlenecks.

- [Disk-Level Query: Group by Disk](https://github.com/Constantine-SRV/IO_Virtual_File_Stats_history/blob/main/selectGroupByDisk.sql)

### 2. **File-Level Performance Query**
For more detailed analysis, use this query to get performance metrics at the individual file level. It provides information on latency, throughput, and bytes transferred for each file on the server.

- [File-Level Query: Per File Statistics](https://github.com/Constantine-SRV/IO_Virtual_File_Stats_history/blob/main/SelectForEachFile.sql)

## Instructions

1. **Step 1: Set Up the Data Collection Table**
   Create the table to store I/O statistics:
   - [Create Table Script](https://github.com/Constantine-SRV/IO_Virtual_File_Stats_history/blob/main/tbl_IO_Virtual_File_Stats.sql)

2. **Step 2: Configure Data Collection**
   Set up a scheduled job (e.g., SQL Server Agent) to run the data collection script every minute:
   - [Data Collection Script](https://github.com/Constantine-SRV/IO_Virtual_File_Stats_history/blob/main/loop.sql)

3. **Step 3: Analyze Disk I/O Performance**
   Start by using the **Disk-Level Performance Query** to understand the load and delays on each disk. This will give you a high-level view of how each disk is performing in terms of throughput and latency:
   - [Group by Disk Query](https://github.com/Constantine-SRV/IO_Virtual_File_Stats_history/blob/main/selectGroupByDisk.sql)

4. **Step 4: Detailed File-Level Analysis**
   If you need more granular data for specific files, run the **File-Level Performance Query**. This query will provide detailed information on I/O performance for each file, helping you identify performance issues at the file level:
   - [File-Level Query](https://github.com/Constantine-SRV/IO_Virtual_File_Stats_history/blob/main/SelectForEachFile.sql)

## Example Use Cases

- **Database Performance Monitoring**: Use this project to identify bottlenecks in disk I/O performance, helping you to optimize SQL Server performance.
- **Historical I/O Analysis**: Track performance trends over time by storing historical data and reviewing past performance.
- **Disk Optimization**: Analyze performance by disk to identify underperforming drives that may need to be upgraded or reconfigured.
