-- T-SQL Stored Procedure Templates
-- Use these templates as starting points for your T2 stored procedures

-- ============================================================================
-- Template 1: SCD2 MERGE Stored Procedure
-- ============================================================================

CREATE PROCEDURE t2.usp_merge_dim_[DIMENSION_NAME]
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @StartTime DATETIME2 = GETDATE();
    DECLARE @RowsAffected INT = 0;
    DECLARE @ErrorNumber INT;
    DECLARE @ErrorMessage NVARCHAR(4000);
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Step 1: Expire old records that have changed
        UPDATE t2.dim_[dimension_name]
        SET 
            expiry_date = GETDATE(),
            is_current = 0,
            updated_at = GETDATE()
        WHERE is_current = 1
        AND [business_key] IN (
            SELECT s.[business_key]
            FROM t1_[dimension_name] s
            INNER JOIN t2.dim_[dimension_name] t 
                ON s.[business_key] = t.[business_key] 
                AND t.is_current = 1
            WHERE s.[column1] <> t.[column1]
               OR s.[column2] <> t.[column2]
               -- Add more change detection columns
        );
        
        SET @RowsAffected = @@ROWCOUNT;
        
        -- Step 2: Insert new versions for changed records
        INSERT INTO t2.dim_[dimension_name] (
            [business_key], [column1], [column2], 
            effective_date, is_current
        )
        SELECT 
            s.[business_key],
            s.[column1],
            s.[column2],
            GETDATE(),
            1
        FROM t1_[dimension_name] s
        WHERE EXISTS (
            SELECT 1 
            FROM t2.dim_[dimension_name] t 
            WHERE t.[business_key] = s.[business_key] 
            AND t.is_current = 0
            AND t.expiry_date = CAST(GETDATE() AS DATE)
        );
        
        -- Step 3: Insert completely new records
        INSERT INTO t2.dim_[dimension_name] (
            [business_key], [column1], [column2],
            effective_date, is_current
        )
        SELECT 
            s.[business_key],
            s.[column1],
            s.[column2],
            GETDATE(),
            1
        FROM t1_[dimension_name] s
        WHERE NOT EXISTS (
            SELECT 1 
            FROM t2.dim_[dimension_name] t 
            WHERE t.[business_key] = s.[business_key]
        );
        
        COMMIT TRANSACTION;
        
        -- Log success
        INSERT INTO t0.pipeline_log (
            pipeline_name, start_time, end_time, status, rows_processed
        )
        VALUES (
            't2.usp_merge_dim_[DIMENSION_NAME]',
            @StartTime,
            GETDATE(),
            'Success',
            @RowsAffected
        );
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        SET @ErrorNumber = ERROR_NUMBER();
        SET @ErrorMessage = ERROR_MESSAGE();
        
        -- Log error
        INSERT INTO t0.pipeline_log (
            pipeline_name, start_time, end_time, status, error_message
        )
        VALUES (
            't2.usp_merge_dim_[DIMENSION_NAME]',
            @StartTime,
            GETDATE(),
            'Failed',
            @ErrorMessage
        );
        
        -- Re-throw error
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END;
GO

-- ============================================================================
-- Template 2: Incremental Fact Load Stored Procedure
-- ============================================================================

CREATE PROCEDURE t2.usp_load_fact_[FACT_NAME]
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @StartTime DATETIME2 = GETDATE();
    DECLARE @LastLoad DATETIME2;
    DECLARE @RowsInserted INT = 0;
    DECLARE @ErrorNumber INT;
    DECLARE @ErrorMessage NVARCHAR(4000);
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Get watermark (last loaded timestamp)
        SELECT @LastLoad = ISNULL(MAX(source_ingested_at), '1900-01-01')
        FROM t2.fact_[fact_name];
        
        -- Insert only new fact records
        INSERT INTO t2.fact_[fact_name] (
            [fact_key], [dimension_key1], [dimension_key2],
            [measure1], [measure2], source_ingested_at
        )
        SELECT 
            s.[fact_key],
            s.[dimension_key1],
            s.[dimension_key2],
            s.[measure1],
            s.[measure2],
            s.ingested_at
        FROM t1_[fact_name] s
        WHERE s.ingested_at > @LastLoad
        AND NOT EXISTS (
            SELECT 1 
            FROM t2.fact_[fact_name] f 
            WHERE f.[fact_key] = s.[fact_key]
        );
        
        SET @RowsInserted = @@ROWCOUNT;
        
        -- Update surrogate keys
        UPDATE f
        SET 
            f.[dimension_key1] = d1.[dimension_key],
            f.[dimension_key2] = d2.[dimension_key]
        FROM t2.fact_[fact_name] f
        LEFT JOIN t2.dim_[dimension1] d1 
            ON f.[business_key1] = d1.[business_key] 
            AND d1.is_current = 1
        LEFT JOIN t2.dim_[dimension2] d2 
            ON f.[business_key2] = d2.[business_key] 
            AND d2.is_current = 1
        WHERE f.[dimension_key1] IS NULL;
        
        COMMIT TRANSACTION;
        
        -- Log success
        INSERT INTO t0.pipeline_log (
            pipeline_name, start_time, end_time, status, rows_processed
        )
        VALUES (
            't2.usp_load_fact_[FACT_NAME]',
            @StartTime,
            GETDATE(),
            'Success',
            @RowsInserted
        );
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        SET @ErrorNumber = ERROR_NUMBER();
        SET @ErrorMessage = ERROR_MESSAGE();
        
        -- Log error
        INSERT INTO t0.pipeline_log (
            pipeline_name, start_time, end_time, status, error_message
        )
        VALUES (
            't2.usp_load_fact_[FACT_NAME]',
            @StartTime,
            GETDATE(),
            'Failed',
            @ErrorMessage
        );
        
        -- Re-throw error
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END;
GO

-- ============================================================================
-- Template 3: Batch Processing Stored Procedure
-- ============================================================================

CREATE PROCEDURE t2.usp_batch_process_[TABLE_NAME]
    @BatchSize INT = 10000
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @RowsProcessed INT = 1;
    DECLARE @TotalRows INT;
    DECLARE @BatchesProcessed INT = 0;
    DECLARE @StartTime DATETIME2 = GETDATE();
    
    -- Get total rows to process
    SELECT @TotalRows = COUNT(*) 
    FROM [source_table] 
    WHERE processed = 0;
    
    -- Process in batches
    WHILE @RowsProcessed > 0
    BEGIN
        BEGIN TRY
            BEGIN TRANSACTION;
            
            -- Create temporary table for batch
            CREATE TABLE #current_batch (
                [key_column] VARCHAR(50),
                [data_column1] VARCHAR(100),
                [data_column2] DECIMAL(12,2)
            );
            
            -- Load batch into temp table
            INSERT INTO #current_batch
            SELECT TOP (@BatchSize) 
                [key_column], [data_column1], [data_column2]
            FROM [source_table]
            WHERE processed = 0
            ORDER BY [key_column];
            
            SET @RowsProcessed = @@ROWCOUNT;
            
            -- Process batch
            INSERT INTO [target_table] (...)
            SELECT ... FROM #current_batch;
            
            -- Mark source records as processed
            UPDATE [source_table]
            SET processed = 1
            WHERE [key_column] IN (
                SELECT [key_column] FROM #current_batch
            );
            
            SET @BatchesProcessed = @BatchesProcessed + 1;
            
            COMMIT TRANSACTION;
            
            -- Clean up temp table
            DROP TABLE #current_batch;
            
            -- Log progress
            PRINT 'Batch ' + CAST(@BatchesProcessed AS VARCHAR(10)) + 
                  ': Processed ' + CAST(@RowsProcessed AS VARCHAR(10)) + ' rows';
            
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0
                ROLLBACK TRANSACTION;
            
            -- Log batch failure
            INSERT INTO t0.error_log (
                component_type, component_name, error_severity, error_message
            )
            VALUES (
                'StoredProcedure',
                't2.usp_batch_process_[TABLE_NAME]',
                'High',
                ERROR_MESSAGE()
            );
            
            -- Re-throw error
            THROW;
        END CATCH
    END
    
    -- Log completion
    INSERT INTO t0.pipeline_log (
        pipeline_name, start_time, end_time, status, rows_processed
    )
    VALUES (
        't2.usp_batch_process_[TABLE_NAME]',
        @StartTime,
        GETDATE(),
        'Success',
        @TotalRows
    );
END;
GO

-- ============================================================================
-- Template 4: Zero-Copy Clone Refresh Stored Procedure
-- ============================================================================

CREATE PROCEDURE t3.usp_refresh_final_clones
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @StartTime DATETIME2 = GETDATE();
    DECLARE @ErrorNumber INT;
    DECLARE @ErrorMessage NVARCHAR(4000);
    
    BEGIN TRY
        -- Drop T5 views first (to avoid dependencies)
        IF OBJECT_ID('t5.vw_[view_name]', 'V') IS NOT NULL
            DROP VIEW t5.vw_[view_name];
        
        -- Drop existing _FINAL clones
        IF OBJECT_ID('t3.[table_name]_FINAL', 'U') IS NOT NULL
            DROP TABLE t3.[table_name]_FINAL;
        
        -- Create new clones (zero-copy)
        CREATE TABLE t3.[table_name]_FINAL AS CLONE OF t3.[table_name];
        
        -- Log success
        INSERT INTO t0.pipeline_log (
            pipeline_name, start_time, end_time, status
        )
        VALUES (
            't3.usp_refresh_final_clones',
            @StartTime,
            GETDATE(),
            'Success'
        );
        
    END TRY
    BEGIN CATCH
        SET @ErrorNumber = ERROR_NUMBER();
        SET @ErrorMessage = ERROR_MESSAGE();
        
        -- Log error
        INSERT INTO t0.pipeline_log (
            pipeline_name, start_time, end_time, status, error_message
        )
        VALUES (
            't3.usp_refresh_final_clones',
            @StartTime,
            GETDATE(),
            'Failed',
            @ErrorMessage
        );
        
        -- Re-throw error
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END;
GO
