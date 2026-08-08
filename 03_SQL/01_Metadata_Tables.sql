/* ============================================================
   PROJECT : Azure Logistics Data Engineering
   FILE    : 01_Metadata_Tables.sql
   PURPOSE : Create metadata/control tables for ETL framework
   ============================================================ */


/* ============================================================
   1. CREATE METADATA SCHEMA
   ============================================================ */

IF NOT EXISTS
(
    SELECT 1
    FROM sys.schemas
    WHERE name = 'metadata'
)
BEGIN
    EXEC('CREATE SCHEMA metadata');
END;
GO


/* ============================================================
   2. OBJECT CONFIGURATION TABLE
   ============================================================ */

IF OBJECT_ID(
    'metadata.OBJECTS_CONFIGURATION',
    'U'
) IS NULL
BEGIN

    CREATE TABLE metadata.OBJECTS_CONFIGURATION
    (
        OBJECT_NAME                 NVARCHAR(100) NOT NULL,

        IS_TRANSACTIONAL            BIT DEFAULT 1,

        IS_RUN                      BIT DEFAULT 1,

        IS_PROCESSED                BIT DEFAULT 0,

        FREQUENCY_IN_MINUTES        BIGINT,

        COLUMNS_NAME                NVARCHAR(MAX),

        KEY_COLUMN_NAME             NVARCHAR(MAX),

        OPERATION_TYPE              NVARCHAR(50),

        SOURCE_NAME                 NVARCHAR(100),

        SOURCE_FILE_NAME            NVARCHAR(500),

        SOURCE_FILE_PATH            NVARCHAR(1000),

        BRONZE_TABLE_NAME           NVARCHAR(500),

        SILVER_TABLE_NAME           NVARCHAR(500),

        GOLD_TABLE_NAME             NVARCHAR(500),

        ARCHIVE_PATH                NVARCHAR(1000),

        IDENTIFIER_COLUMN           NVARCHAR(500),

        IS_FULL_LOAD                BIT DEFAULT 1,

        SILVER_COLUMN_NAME          NVARCHAR(MAX),

        UPDATED_ON                  DATETIME2(7),

        LAST_PROCESSED_CHECKPOINT   DATETIME2(7)
    );

END;
GO
