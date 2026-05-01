-- =============================================================================
-- 02_seed_data.sql  –  Populates source tables and etl_control metadata
-- =============================================================================

-- ---------------------------------------------------------------------------
-- SOURCE DATA: source_products  (used by 'pipeline-B' db connector)
-- ---------------------------------------------------------------------------
INSERT INTO source_products (product_name, category, price, stock, last_modified) VALUES
    ('Laptop Pro 15',     'Electronics',  1299.99, 45,  NOW() - INTERVAL '10 days'),
    ('Wireless Mouse',    'Electronics',    29.99, 200, NOW() - INTERVAL '9 days'),
    ('Standing Desk',     'Furniture',     449.00, 30,  NOW() - INTERVAL '8 days'),
    ('USB-C Hub',         'Electronics',    49.99, 150, NOW() - INTERVAL '7 days'),
    ('Ergonomic Chair',   'Furniture',     329.00, 25,  NOW() - INTERVAL '6 days'),
    ('Monitor 27"',       'Electronics',   399.99, 60,  NOW() - INTERVAL '5 days'),
    ('Mechanical Keyboard','Electronics',  129.99, 80,  NOW() - INTERVAL '4 days'),
    ('Webcam HD',         'Electronics',    79.99, 120, NOW() - INTERVAL '3 days'),
    ('Desk Lamp',         'Office',         39.99, 90,  NOW() - INTERVAL '2 days'),
    ('Notebook Set',      'Office',         14.99, 300, NOW() - INTERVAL '1 day');

-- ---------------------------------------------------------------------------
-- ETL CONTROL METADATA
-- ---------------------------------------------------------------------------

-- pipeline-A: CSV full load, no dependencies (runs first)
INSERT INTO etl_control
    (pipeline_name, source_type, source_options, destination_table, load_type, incremental_key, dependencies, is_active)
VALUES
    ('pipeline-A',
     'csv',
     '{"path": "/data/source_data.csv"}',
     'dest_csv_customers',
     'full',
     NULL,
     '{}',
     TRUE);

-- pipeline-B: DB full load, depends on pipeline-A
INSERT INTO etl_control
    (pipeline_name, source_type, source_options, destination_table, load_type, incremental_key, dependencies, is_active)
VALUES
    ('pipeline-B',
     'db',
     '{"table": "source_products"}',
     'dest_products',
     'full',
     NULL,
     ARRAY['pipeline-A'],
     TRUE);

-- pipeline-api: API incremental load, depends on pipeline-A
INSERT INTO etl_control
    (pipeline_name, source_type, source_options, destination_table, load_type, incremental_key, dependencies, is_active)
VALUES
    ('pipeline-api',
     'api',
     '{"url": "http://mock-api:8080/data", "since_param": "since"}',
     'dest_api_events',
     'incremental',
     'last_modified',
     ARRAY['pipeline-A'],
     TRUE);

-- pipeline-fail: points to a non-existent CSV file → will FAIL with an error log
INSERT INTO etl_control
    (pipeline_name, source_type, source_options, destination_table, load_type, incremental_key, dependencies, is_active)
VALUES
    ('pipeline-fail',
     'csv',
     '{"path": "/data/nonexistent_file.csv"}',
     'dest_csv_customers',
     'full',
     NULL,
     '{}',
     TRUE);

-- cycle-A and cycle-B: circular dependency → orchestrator must detect and abort
INSERT INTO etl_control
    (pipeline_name, source_type, source_options, destination_table, load_type, incremental_key, dependencies, is_active)
VALUES
    ('cycle-A',
     'csv',
     '{"path": "/data/source_data.csv"}',
     'dest_csv_customers',
     'full',
     NULL,
     ARRAY['cycle-B'],
     TRUE);

INSERT INTO etl_control
    (pipeline_name, source_type, source_options, destination_table, load_type, incremental_key, dependencies, is_active)
VALUES
    ('cycle-B',
     'csv',
     '{"path": "/data/source_data.csv"}',
     'dest_csv_customers',
     'full',
     NULL,
     ARRAY['cycle-A'],
     TRUE);
