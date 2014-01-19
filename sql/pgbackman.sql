--
--
--
--

\echo '# [Creating user: pgbackman_user_rw]\n'
CREATE USER pgbackman_user_rw;

\echo '# [Creating user: pgbackman_user_ro]\n'
CREATE USER pgbackman_user_ro;

\echo '# [Creating database: pgbackman]\n'
CREATE DATABASE pgbackman OWNER pgbackman_user_rw;

\c pgbackman

BEGIN;

-- ------------------------------------------------------
-- Table: backup_server
--
-- @Description: Information about the backup servers
--               avaliable in our system
--
-- Attributes:
--
-- @server_id:
-- @registered:
-- @hostname:
-- @status:
-- @remarks:
-- ------------------------------------------------------

\echo '# [Creating table: backup_server]\n'

CREATE TABLE backup_server(

  server_id SERIAL NOT NULL,
  registered TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  hostname TEXT NOT NULL,
  domain_name TEXT NOT NULL,
  status CHARACTER VARYING(20) DEFAULT 'RUNNING' NOT NULL,
  remarks TEXT
);

ALTER TABLE backup_server ADD PRIMARY KEY (hostname,domain_name);
CREATE UNIQUE INDEX ON backup_server(server_id);

ALTER TABLE backup_server OWNER TO pgbackman_user_rw;

-- ------------------------------------------------------
-- Table: pgsql_node
--
-- @Description: Information about the PostgreSQL servers
--               registered in our system
--
-- Attributes:
--
-- @node_id:
-- @registered:
-- @hostname:
-- @pgport:
-- @admin_user:
-- @pg_version
-- @status:
-- @remarks:
-- ------------------------------------------------------

\echo '# [Creating table: pgsql_node]\n'

CREATE TABLE pgsql_node(

  node_id SERIAL NOT NULL,
  registered TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  hostname TEXT NOT NULL,
  domain_name TEXT NOT NULL,
  pgport INTEGER DEFAULT '5432' NOT NULL,
  admin_user TEXT DEFAULT 'postgres' NOT NULL,
  pg_version CHARACTER VARYING(5),
  status CHARACTER VARYING(20) DEFAULT 'RUNNING' NOT NULL,
  remarks TEXT
);

ALTER TABLE pgsql_node ADD PRIMARY KEY (hostname,domain_name,pgport,admin_user);
CREATE UNIQUE INDEX ON pgsql_node(node_id);

ALTER TABLE pgsql_node OWNER TO pgbackman_user_rw;


-- ------------------------------------------------------
-- Table: server_code
--
-- @Description: Server status
--
-- Attributes:
--
-- @code:
-- @description:
-- ------------------------------------------------------

\echo '# [Creating table: server_code]\n'

CREATE TABLE server_status(

  code CHARACTER VARYING(20) NOT NULL,
  description TEXT
);

ALTER TABLE server_status ADD PRIMARY KEY (code);
ALTER TABLE server_status OWNER TO pgbackman_user_rw;


-- ------------------------------------------------------
-- Table: backup_code
--
-- @Description: Backup jobs avaliable in Pgbackman
--
-- Attributes:
--
-- @code:
-- @description:
-- ------------------------------------------------------

\echo '# [Creating table: backup_code]\n'

CREATE TABLE backup_code(

  code CHARACTER VARYING(20) NOT NULL,
  description TEXT
);

ALTER TABLE backup_code ADD PRIMARY KEY (code);
ALTER TABLE backup_code OWNER TO pgbackman_user_rw;

-- ------------------------------------------------------
-- Table: job_definition_status
--
-- @Description: Status codes for Pgbackman job definitions
--
-- Attributes:
--
-- @code:
-- @description:
-- ------------------------------------------------------

\echo '# [Creating table: job_definition_status]\n'

CREATE TABLE job_definition_status(

  code CHARACTER VARYING(20) NOT NULL,
  description TEXT
);

ALTER TABLE job_definition_status ADD PRIMARY KEY (code);
ALTER TABLE job_definition_status OWNER TO pgbackman_user_rw;

-- ------------------------------------------------------
-- Table: job_execution_status
--
-- @Description: Status codes for job executions
--
-- Attributes:
--
-- @code:
-- @description:
-- ------------------------------------------------------

\echo '# [Creating table: job_execution_status]\n'

CREATE TABLE job_execution_status(

  code CHARACTER VARYING(20) NOT NULL,
  description TEXT
);

ALTER TABLE job_execution_status ADD PRIMARY KEY (code);
ALTER TABLE job_execution_status OWNER TO pgbackman_user_rw;

-- ------------------------------------------------------
-- Table: backup_server_default_config
--
-- @Description: Default configuration values for 
--               backup servers.
--
-- Attributes:
--
-- @parameter:
-- @value:
-- @description:
-- ------------------------------------------------------

\echo '# [Creating table: backup_server_default_config]\n'

CREATE TABLE backup_server_default_config(

  parameter TEXT NOT NULL,
  value TEXT NOT NULL,
  description TEXT
);

ALTER TABLE backup_server_default_config ADD PRIMARY KEY (parameter);
ALTER TABLE backup_server_default_config OWNER TO pgbackman_user_rw;


-- ------------------------------------------------------
-- Table: pgsql_node_default_config
--
-- @Description: Default configuration values for 
--               postgresql servers.
--
-- Attributes:
--
-- @parameter:
-- @value:
-- @description:
-- ------------------------------------------------------

\echo '# [Creating table: pgsql_node_default_config]\n'

CREATE TABLE pgsql_node_default_config(

  parameter TEXT NOT NULL,
  value TEXT NOT NULL,
  description TEXT
);

ALTER TABLE pgsql_node_default_config ADD PRIMARY KEY (parameter);
ALTER TABLE pgsql_node_default_config OWNER TO pgbackman_user_rw;

-- ------------------------------------------------------
-- Table: job_queue
--
-- @Description: 
--
-- Attributes:
--
-- @parameter:
-- @value:
-- @description:
-- ------------------------------------------------------

\echo '# [Creating table: job_queue]\n'

CREATE TABLE job_queue(
  id BIGSERIAL,
  registered TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  backup_server_id INTEGER NOT NULL,
  pgsql_node_id INTEGER NOT NULL,
  is_assigned BOOLEAN NOT NULL DEFAULT 'f'
);

ALTER TABLE job_queue ADD PRIMARY KEY (backup_server_id,pgsql_node_id,is_assigned);
ALTER TABLE job_queue OWNER TO pgbackman_user_rw;



-- ------------------------------------------------------
-- Table: backup_job_definition
--
-- @Description: Backup jobs defined in Pgbackman 
--
-- Attributes:
--
-- @job_id
-- @registered
-- @backup_server_id
-- @pgsql_node_id
-- @pg_version
-- @dbname
-- @minutes_cron
-- @hours_cron
-- @weekday_cron
-- @month_cron
-- @day_month_cron
-- @backup_code
-- @encryption: NOT IMPLEMENTED
-- @retention_period
-- @retention_redundancy
-- @excluded_tables
-- @job_status
-- @remarks
-- ------------------------------------------------------

\echo '# [Creating table: backup_job_definition]\n'

CREATE TABLE backup_job_definition(

  job_id SERIAL UNIQUE,
  registered TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  backup_server_id INTEGER NOT NULL,
  pgsql_node_id INTEGER NOT NULL,
  dbname TEXT NOT NULL,
  minutes_cron CHARACTER VARYING(255) DEFAULT '*',
  hours_cron CHARACTER VARYING(255) DEFAULT '*',
  weekday_cron CHARACTER VARYING(255) DEFAULT '*',
  month_cron CHARACTER VARYING(255) DEFAULT '*',
  day_month_cron CHARACTER VARYING(255) DEFAULT '*',
  backup_code CHARACTER VARYING(10) NOT NULL,
  encryption boolean DEFAULT false NOT NULL,
  retention_period interval DEFAULT '7 days'::interval NOT NULL,
  retention_redundancy integer DEFAULT 1 NOT NULL,
  extra_parameters TEXT DEFAULT '',
  job_status CHARACTER VARYING(20) NOT NULL,
  remarks TEXT
);

ALTER TABLE backup_job_definition ADD PRIMARY KEY (pgsql_node_id,dbname,backup_code,extra_parameters);

ALTER TABLE backup_job_definition OWNER TO pgbackman_user_rw;


-- ------------------------------------------------------
-- Table: backup_job_catalog
--
-- @Description: Catalog information about executed
--               backup jobs.
--
-- Attributes:
--
-- @id
-- @registered
-- @job_id
-- @backup_server
-- @pgsql_node
-- @dbname
-- @started
-- @finnished
-- @duration
-- @pg_dump_file_size
-- @pg_dump_file
-- @global_data_file
-- @db_parameters_file
-- @log_file
-- @execution_status
-- ------------------------------------------------------

\echo '# [Creating table: backup_job_catalog]\n'

CREATE TABLE backup_job_catalog(

  id BIGSERIAL,
  registered TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  job_id INTEGER NOT NULL,
  backup_server_id INTEGER NOT NULL,
  pgsql_node_id INTEGER NOT NULL,
  dbname TEXT NOT NULL,
  started TIMESTAMP WITH TIME ZONE,
  finnished TIMESTAMP WITH TIME ZONE,
  duration INTERVAL,
  pg_dump_file_size BIGINT,
  pg_dump_file TEXT NOT NULL,
  global_data_file TEXT,
  db_parameters_file TEXT,
  log_file TEXT NOT NULL,
  execution_status TEXT
);

ALTER TABLE backup_job_catalog ADD PRIMARY KEY (id);
ALTER TABLE backup_job_catalog OWNER TO pgbackman_user_rw;


-- ------------------------------------------------------
-- Table: backup_server_config
--
-- @Description: Configuration of backup servers.
--
-- Attributes:
--
-- @server_id
-- @parameter
-- @value
-- ------------------------------------------------------

\echo '# [Creating table: backup_server_config]\n'

CREATE TABLE backup_server_config(

  server_id INTEGER NOT NULL REFERENCES backup_server (server_id),
  parameter TEXT NOT NULL,
  value TEXT NOT NULL,
  description TEXT
);

ALTER TABLE backup_server_config ADD PRIMARY KEY (server_id,parameter);
ALTER TABLE backup_server_config OWNER TO pgbackman_user_rw;

-- ------------------------------------------------------
-- Table: pgsql_node_config
--
-- @Description: Configuration of postgresql servers.
--
-- Attributes:
--
-- @node_id
-- @parameter
-- @value
-- ------------------------------------------------------

\echo '# [Creating table: pgsql_node_config]\n'

CREATE TABLE pgsql_node_config(

  node_id INTEGER NOT NULL NOT NULL REFERENCES pgsql_node (node_id),
  parameter TEXT NOT NULL,
  value TEXT NOT NULL,
  description TEXT
);

ALTER TABLE pgsql_node_config ADD PRIMARY KEY (node_id,parameter);
ALTER TABLE pgsql_node_config OWNER TO pgbackman_user_rw;

-- ------------------------------------------------------
-- Contraints
-- ------------------------------------------------------

\echo '# [Creating constraints]\n'

ALTER TABLE ONLY backup_server
    ADD FOREIGN KEY (status) REFERENCES server_status(code) MATCH FULL ON DELETE RESTRICT;

ALTER TABLE ONLY pgsql_node
    ADD FOREIGN KEY (status) REFERENCES server_status(code) MATCH FULL ON DELETE RESTRICT;

ALTER TABLE ONLY job_queue
    ADD FOREIGN KEY (backup_server_id) REFERENCES backup_server (server_id) MATCH FULL ON DELETE RESTRICT;

ALTER TABLE ONLY job_queue
    ADD FOREIGN KEY (pgsql_node_id) REFERENCES pgsql_node (node_id) MATCH FULL ON DELETE RESTRICT;

ALTER TABLE ONLY backup_job_definition
    ADD FOREIGN KEY (backup_server_id) REFERENCES backup_server (server_id) MATCH FULL ON DELETE RESTRICT;

ALTER TABLE ONLY backup_job_definition
    ADD FOREIGN KEY (pgsql_node_id) REFERENCES pgsql_node (node_id) MATCH FULL ON DELETE RESTRICT;

ALTER TABLE ONLY backup_job_definition
    ADD FOREIGN KEY (backup_code) REFERENCES backup_code (code) MATCH FULL ON DELETE RESTRICT;

ALTER TABLE ONLY backup_job_definition
    ADD FOREIGN KEY (job_status) REFERENCES  job_definition_status(code) MATCH FULL ON DELETE RESTRICT;


ALTER TABLE ONLY backup_job_catalog
    ADD FOREIGN KEY (job_id) REFERENCES  backup_job_definition (job_id) MATCH FULL ON DELETE RESTRICT;

ALTER TABLE ONLY backup_job_catalog
    ADD FOREIGN KEY (backup_server_id) REFERENCES  backup_server (server_id) MATCH FULL ON DELETE RESTRICT;

ALTER TABLE ONLY backup_job_catalog
    ADD FOREIGN KEY (pgsql_node_id) REFERENCES pgsql_node (node_id) MATCH FULL ON DELETE RESTRICT;

ALTER TABLE ONLY backup_job_catalog
    ADD FOREIGN KEY (execution_status) REFERENCES job_execution_status (code) MATCH FULL ON DELETE RESTRICT;


-- ------------------------------------------------------
-- Init
-- ------------------------------------------------------

\echo '# [Init: backup_code]\n'

INSERT INTO server_status (code,description) VALUES ('RUNNING','Server is active and running');
INSERT INTO server_status (code,description) VALUES ('DOWN','Server is down');

\echo '# [Init: backup_code]\n'

INSERT INTO backup_code (code,description) VALUES ('FULL','Full Backup of a database. Schema + data + owner globals + db_parameters');
INSERT INTO backup_code (code,description) VALUES ('SCHEMA','Schema backup of a database. Schema + owner globals + db_parameters');
INSERT INTO backup_code (code,description) VALUES ('DATA','Data backup of the database.');
INSERT INTO backup_code (code,description) VALUES ('CONFIG','Backup of the configuration files');

\echo '# [Init: job_definition_status]\n'

INSERT INTO job_definition_status (code,description) VALUES ('ACTIVE','Backup job activated and in production');
INSERT INTO job_definition_status (code,description) VALUES ('STOPPED','Backup job stopped');


\echo '# [Init: job_execution_status]\n'

INSERT INTO job_execution_status (code,description) VALUES ('SUCCEEDED','Job finnished without errors');
INSERT INTO job_execution_status (code,description) VALUES ('ERROR','Job finnished with an error');
INSERT INTO job_execution_status (code,description) VALUES ('WARNING','Job finnished with a warning');

\echo '# [Init: backup_server_default_config]\n'

INSERT INTO backup_server_default_config (parameter,value,description) VALUES ('root_backup_partition','/srv/pgbackman','Main partition used by pgbackman');
INSERT INTO backup_server_default_config (parameter,value,description) VALUES ('root_cron_file','/etc/cron.d/pgbackman','Crontab file used by pgbackman');
INSERT INTO backup_server_default_config (parameter,value,description) VALUES ('domain','example.org','Default domain');
INSERT INTO backup_server_default_config (parameter,value,description) VALUES ('backup_server_status','RUNNING','Default backup server status');


\echo '# [Init: pgsql_node_default_config]\n'

INSERT INTO pgsql_node_default_config (parameter,value,description) VALUES ('pgnode_backup_partition','/srv/pgbackman/%%pgnode%%','Partition to save pgbackman information for a pgnode');
INSERT INTO pgsql_node_default_config (parameter,value,description) VALUES ('pg_node_cron_file','/etc/cron.d/%%pgnode%%_backups','Crontab file for pgnode in the backup server');
INSERT INTO pgsql_node_default_config (parameter,value,description) VALUES ('encryption','false','GnuPG encryption');
INSERT INTO pgsql_node_default_config (parameter,value,description) VALUES ('retention_period','7 days','Retention period for a backup job');
INSERT INTO pgsql_node_default_config (parameter,value,description) VALUES ('retention_redundancy','1','Retention redundancy for a backup job');
INSERT INTO pgsql_node_default_config (parameter,value,description) VALUES ('pgport','5432','postgreSQL port');
INSERT INTO pgsql_node_default_config (parameter,value,description) VALUES ('admin_user','postgres','postgreSQL admin user');
INSERT INTO pgsql_node_default_config (parameter,value,description) VALUES ('domain','example.org','Default domain');
INSERT INTO pgsql_node_default_config (parameter,value,description) VALUES ('pgsql_node_status','RUNNING','pgsql node status');
INSERT INTO pgsql_node_default_config (parameter,value,description) VALUES ('backup_job_status','ACTIVE','Backup job status');
INSERT INTO pgsql_node_default_config (parameter,value,description) VALUES ('backup_code','FULL','Backup job code');
INSERT INTO pgsql_node_default_config (parameter,value,description) VALUES ('backup_minutes_interval','01-59','Backup minutes interval');
INSERT INTO pgsql_node_default_config (parameter,value,description) VALUES ('backup_hours_interval','01-06','Backup hours interval');
INSERT INTO pgsql_node_default_config (parameter,value,description) VALUES ('backup_weekday_cron','*','Backup weekday cron default');
INSERT INTO pgsql_node_default_config (parameter,value,description) VALUES ('backup_month_cron','*','Backup month cron default');
INSERT INTO pgsql_node_default_config (parameter,value,description) VALUES ('backup_day_month_cron','*','Backup day_month cron default');
INSERT INTO pgsql_node_default_config (parameter,value,description) VALUES ('extra_parameters','','Extra backup parameters');



-- ------------------------------------------------------------
-- View: jobs_queue
--
-- ------------------------------------------------------------

CREATE OR REPLACE VIEW jobs_queue AS 
SELECT a.id,
       a.registered,
       a.backup_server_id,
       b.hostname || '.' || b.domain_name AS backup_server,
       a.pgsql_node_id,
       c.hostname || '.' || b.domain_name AS pgsql_node,
       a.is_assigned
FROM job_queue a
INNER JOIN backup_server b ON a.backup_server_id = b.server_id
INNER JOIN pgsql_node c ON a.pgsql_node_id = c.node_id
ORDER BY a.registered ASC;


-- ------------------------------------------------------------
-- Function: update_backup_server_configuration()
--
-- ------------------------------------------------------------

CREATE OR REPLACE FUNCTION update_backup_server_configuration() RETURNS TRIGGER
 LANGUAGE plpgsql 
 SECURITY INVOKER 
 SET search_path = public, pg_temp
 AS $$
 DECLARE

 BEGIN

  EXECUTE 'INSERT INTO backup_server_config (server_id,parameter,value,description) 
  	   SELECT $1,parameter,value,description FROM backup_server_default_config'
  USING NEW.server_id;

RETURN NULL;

EXCEPTION
  WHEN transaction_rollback THEN
   RAISE EXCEPTION 'Transaction rollback when updating backup_server_config';
   RETURN NULL;
  WHEN syntax_error_or_access_rule_violation THEN
   RAISE EXCEPTION 'Syntax or access error when updating backup_server_config';
   RETURN NULL;
  WHEN foreign_key_violation THEN
   RAISE EXCEPTION 'Caught foreign_key_violation when updating backup_server_config';
   RETURN NULL;
  WHEN unique_violation THEN
   RAISE EXCEPTION 'Duplicate key value violates unique constraint when updating backup_server_config';
   RETURN NULL;
END;
$$;

ALTER FUNCTION update_backup_server_configuration() OWNER TO pgbackman_user_rw;

CREATE TRIGGER update_backup_server_configuration AFTER INSERT
    ON backup_server FOR EACH ROW
    EXECUTE PROCEDURE update_backup_server_configuration();


-- ------------------------------------------------------------
-- Function: update_pgsql_node_configuration()
--
-- ------------------------------------------------------------

CREATE OR REPLACE FUNCTION update_pgsql_node_configuration() RETURNS TRIGGER
 LANGUAGE plpgsql 
 SECURITY INVOKER 
 SET search_path = public, pg_temp
 AS $$
 BEGIN

  EXECUTE 'INSERT INTO pgsql_node_config (node_id,parameter,value,description) 
  	   SELECT $1,parameter,replace(replace(value,''%%pgnode%%'',$2),''.'',''_''),description FROM pgsql_node_default_config'
  USING NEW.node_id,
  	NEW.hostname || '.' || NEW.domain_name;

RETURN NULL;

EXCEPTION
  WHEN transaction_rollback THEN
   RAISE EXCEPTION 'Transaction rollback when updating pgsql_node_config';
   RETURN NULL;
  WHEN syntax_error_or_access_rule_violation THEN
   RAISE EXCEPTION 'Syntax or access error when updating pgsql_node_config';
   RETURN NULL;
  WHEN foreign_key_violation THEN
   RAISE EXCEPTION 'Caught foreign_key_violation when updating pgsql_node_config';
   RETURN NULL;
  WHEN unique_violation THEN
   RAISE EXCEPTION 'Duplicate key value violates unique constraint when updating pgsql_node_config';
   RETURN NULL;
END;
$$;

ALTER FUNCTION update_backup_server_configuration() OWNER TO pgbackman_user_rw;

CREATE TRIGGER update_pgsql_node_configuration AFTER INSERT
    ON pgsql_node FOR EACH ROW
    EXECUTE PROCEDURE update_pgsql_node_configuration();

-- ------------------------------------------------------------
-- Function: update_job_queue()
--
-- ------------------------------------------------------------

CREATE OR REPLACE FUNCTION update_job_queue() RETURNS TRIGGER
 LANGUAGE plpgsql 
 SECURITY INVOKER 
 SET search_path = public, pg_temp
 AS $$
 DECLARE
  srv_cnt INTEGER := -1;
  backup_server_ TEXT := '';
  pgsql_node_ TEXT :='';
 BEGIN

-- --------------------------
-- Inserting a new backup job
-- --------------------------

 IF (TG_OP = 'INSERT' ) THEN

  SELECT count(*) FROM job_queue WHERE backup_server_id = NEW.backup_server_id AND pgsql_node_id = NEW.pgsql_node_id AND is_assigned IS FALSE INTO srv_cnt;
  SELECT hostname || '.' || domain_name FROM backup_server WHERE server_id = NEW.backup_server_id INTO backup_server_; 
  SELECT hostname || '.' || domain_name FROM pgsql_node WHERE node_id = NEW.pgsql_node_id INTO pgsql_node_; 

  IF srv_cnt = 0 THEN
   EXECUTE 'INSERT INTO job_queue (backup_server_id,pgsql_node_id) VALUES ($1,$2)'
   USING NEW.backup_server_id,
         NEW.pgsql_node_id;

   PERFORM pg_notify('channel_BS' || NEW.backup_server_id || '_PG' || NEW.pgsql_node_id,'Backup jobs for ' || pgsql_node_ || ' updated on ' || backup_server_);
  END IF;  

-- --------------------------
-- Updating a backup job
-- --------------------------

 ELSEIF (TG_OP = 'UPDATE') THEN

  --
  -- The backup job has not been moved to another backup server
  --

  IF (OLD.backup_server_id = NEW.backup_server_id) THEN

    SELECT count(*) FROM job_queue WHERE backup_server_id = NEW.backup_server_id AND pgsql_node_id = NEW.pgsql_node_id AND is_assigned IS FALSE INTO srv_cnt;
    SELECT hostname || '.' || domain_name FROM backup_server WHERE server_id = NEW.backup_server_id INTO backup_server_; 
    SELECT hostname || '.' || domain_name FROM pgsql_node WHERE node_id = NEW.pgsql_node_id INTO pgsql_node_; 

    IF srv_cnt = 0 THEN
     EXECUTE 'INSERT INTO job_queue (backup_server_id,pgsql_node_id) VALUES ($1,$2)'
     USING NEW.backup_server_id,
           NEW.pgsql_node_id;

     PERFORM pg_notify('channel_BS' || NEW.backup_server_id || '_PG' || NEW.pgsql_node_id,'Backup jobs for ' || pgsql_node_ || ' updated on ' || backup_server_);
    END IF;  

  --
  -- The backup job has been moved to another backup server
  --  

  ELSEIF (OLD.backup_server_id <> NEW.backup_server_id) THEN
 
    SELECT count(*) FROM job_queue WHERE backup_server_id = NEW.backup_server_id AND pgsql_node_id = NEW.pgsql_node_id AND is_assigned IS FALSE INTO srv_cnt;
    SELECT hostname || '.' || domain_name FROM backup_server WHERE server_id = NEW.backup_server_id INTO backup_server_; 
    SELECT hostname || '.' || domain_name FROM pgsql_node WHERE node_id = NEW.pgsql_node_id INTO pgsql_node_; 

    IF srv_cnt = 0 THEN
     EXECUTE 'INSERT INTO job_queue (backup_server_id,pgsql_node_id) VALUES ($1,$2)'
     USING NEW.backup_server_id,
           NEW.pgsql_node_id;

     PERFORM pg_notify('channel_BS' || NEW.backup_server_id || '_PG' || NEW.pgsql_node_id,'Backup jobs for ' || pgsql_node_ || ' updated on ' || backup_server_);
    END IF;  

    SELECT count(*) FROM job_queue WHERE backup_server_id = OLD.backup_server_id AND pgsql_node_id = NEW.pgsql_node_id AND is_assigned IS FALSE INTO srv_cnt;
    SELECT hostname || '.' || domain_name FROM backup_server WHERE server_id = OLD.backup_server_id INTO backup_server_; 
    SELECT hostname || '.' || domain_name FROM pgsql_node WHERE node_id = NEW.pgsql_node_id INTO pgsql_node_; 

    IF srv_cnt = 0 THEN
     EXECUTE 'INSERT INTO job_queue (backup_server_id,pgsql_node_id) VALUES ($1,$2)'
     USING OLD.backup_server_id,
           NEW.pgsql_node_id;

     PERFORM pg_notify('channel_BS' || OLD.backup_server_id || '_PG' || NEW.pgsql_node_id,'Backup jobs for ' || pgsql_node_ || ' updated on ' || backup_server_);
    END IF;  

  END IF;

-- --------------------------
-- Deleting a backup job
-- --------------------------

 ELSEIF (TG_OP = 'DELETE') THEN

  SELECT count(*) FROM job_queue WHERE backup_server_id = OLD.backup_server_id AND pgsql_node_id = OLD.pgsql_node_id AND is_assigned IS FALSE INTO srv_cnt;
  SELECT hostname || '.' || domain_name FROM backup_server WHERE server_id = OLD.backup_server_id INTO backup_server_; 
  SELECT hostname || '.' || domain_name FROM pgsql_node WHERE node_id = OLD.pgsql_node_id INTO pgsql_node_; 

  IF srv_cnt = 0 THEN
   EXECUTE 'INSERT INTO job_queue (backup_server_id,pgsql_node_id) VALUES ($1,$2)'
   USING OLD.backup_server_id,
         OLD.pgsql_node_id;

   PERFORM pg_notify('channel_BS' || OLD.backup_server_id || '_PG' || OLD.pgsql_node_id,'Backup jobs for ' || pgsql_node_ || ' updated on ' || backup_server_);
  END IF;         

 END IF;

RETURN NULL;

EXCEPTION
  WHEN transaction_rollback THEN
   RAISE EXCEPTION 'Transaction rollback when updating job_queue';
   RETURN NULL;
  WHEN syntax_error_or_access_rule_violation THEN
   RAISE EXCEPTION 'Syntax or access error when updating job_queue';
   RETURN NULL;
  WHEN foreign_key_violation THEN
   RAISE EXCEPTION 'Caught foreign_key_violation when updating job_queue';
   RETURN NULL;
  WHEN unique_violation THEN
   RAISE EXCEPTION 'Duplicate key value violates unique constraint when updating job_queue';
   RETURN NULL;
END;
$$;

ALTER FUNCTION update_job_queue() OWNER TO pgbackman_user_rw;

CREATE TRIGGER update_job_queue AFTER INSERT OR UPDATE OR DELETE
    ON backup_job_definition FOR EACH ROW 
    EXECUTE PROCEDURE update_job_queue();


-- ------------------------------------------------------------
-- Function: get_next_job()
--
-- ------------------------------------------------------------

CREATE OR REPLACE FUNCTION get_next_job(TEXT) RETURNS SETOF job_queue
 LANGUAGE plpgsql 
 SECURITY INVOKER 
 SET search_path = public, pg_temp
 AS $$
 DECLARE
  backup_server_ ALIAS FOR $1;
  assigned_id BIGINT;
 BEGIN

--
-- We got the idea for this function from 
-- https://github.com/ryandotsmith/queue_classic/
-- 
-- If we can not get a lock right away for SELECT FOR UPDATE
-- we abort the select with NOWAIT, wait random() ms. and try again.
-- With this we try to avoid problems in system with a lot of 
-- concurrency processes trying to get a job assigned.
--

  LOOP
    BEGIN
      EXECUTE 'SELECT id' 
        || ' FROM jobs_queue'
        || ' WHERE backup_server = $1'
        || ' AND is_assigned IS FALSE'
        || ' LIMIT 1'
        || ' FOR UPDATE NOWAIT'
      INTO assigned_id
      USING backup_server_;
      EXIT;
    EXCEPTION
      WHEN lock_not_available THEN
        -- do nothing. loop again and hope we get a lock
    END;

    PERFORM pg_sleep(random());

  END LOOP;

  RETURN QUERY EXECUTE 'UPDATE job_queue'
    || ' SET is_assigned = TRUE'
    || ' WHERE id = $1'
    || ' RETURNING *'
  USING assigned_id;

 END;
$$;

ALTER FUNCTION get_next_job(TEXT) OWNER TO pgbackman_user_rw;

-- ------------------------------------------------------------
-- Function: register_backup_server()
--
-- ------------------------------------------------------------

CREATE OR REPLACE FUNCTION register_backup_server(TEXT,TEXT,CHARACTER VARYING,TEXT) RETURNS BOOLEAN
 LANGUAGE plpgsql 
 SECURITY INVOKER 
 SET search_path = public, pg_temp
 AS $$
 DECLARE
 
  hostname_ ALIAS FOR $1;
  domain_name_ ALIAS FOR $2;
  status_ ALIAS FOR $3;
  remarks_ ALIAS FOR $4;  

  server_cnt INTEGER;
 BEGIN

   IF domain_name_ = '' OR domain_name_ IS NULL THEN
    domain_name_ := get_default_backup_server_parameter('domain');
   END IF;

   IF status_ = '' OR status_ IS NULL THEN
    status_ := get_default_backup_server_parameter('backup_server_status');
   END IF;

   SELECT count(*) AS cnt FROM backup_server WHERE hostname = hostname_ AND domain_name = domain_name_ INTO server_cnt;

   IF server_cnt = 0 THEN     

    EXECUTE 'INSERT INTO backup_server (hostname,domain_name,status,remarks) VALUES ($1,$2,$3,$4)'
    USING hostname_,
          domain_name_,
          status_,
          remarks_;         

   ELSIF  server_cnt > 0 THEN

    EXECUTE 'UPDATE backup_server SET status = $3, remarks = $4 WHERE hostname = $1 AND domain_name = $2'
    USING hostname_,
          domain_name_,
          status_,
          remarks_;	

   END IF;

   RETURN TRUE;
 EXCEPTION
  WHEN transaction_rollback THEN
   RAISE EXCEPTION 'Transaction rollback when updating backup_server';
   RETURN FALSE;
  WHEN syntax_error_or_access_rule_violation THEN
   RAISE EXCEPTION 'Syntax or access error when updating backup_server';
   RETURN FALSE;
  WHEN foreign_key_violation THEN
   RAISE EXCEPTION 'Caught foreign_key_violation when updating backup_server';
   RETURN FALSE;
  WHEN unique_violation THEN
   RAISE EXCEPTION 'Duplicate key value violates unique constraint when updating backup_server';
   RETURN FALSE;
END;
$$;

ALTER FUNCTION register_backup_server(TEXT,TEXT,CHARACTER VARYING,TEXT) OWNER TO pgbackman_user_rw;


-- ------------------------------------------------------------
-- Function: delete_backup_server()
--
-- ------------------------------------------------------------

CREATE OR REPLACE FUNCTION delete_backup_server(TEXT) RETURNS BOOLEAN
 LANGUAGE plpgsql 
 SECURITY INVOKER 
 SET search_path = public, pg_temp
 AS $$
 DECLARE
 
  backup_server_ ALIAS FOR $1;
  server_id_ INTEGER;
 BEGIN

 SELECT server_id FROM backup_server WHERE backup_server_ = hostname || '.' || domain_name  INTO server_id_;

   IF server_id_ IS NOT NULL THEN    
   
    EXECUTE 'DELETE FROM backup_server WHERE server_id = $1'
    USING server_id_;

    RETURN TRUE;
   ELSE
    RAISE EXCEPTION 'Backup server with SrvID = % does not exist',server_id_ USING HINT = 'Please check the SrvID value you want to delete';
    RETURN FALSE;
   END IF; 

END;
$$;

ALTER FUNCTION delete_backup_server(TEXT) OWNER TO pgbackman_user_rw;


-- ------------------------------------------------------------
-- Function: show_backup_servers()
--
-- ------------------------------------------------------------

CREATE OR REPLACE FUNCTION show_backup_servers() RETURNS TEXT 
 LANGUAGE plpgsql 
 SECURITY INVOKER 
 SET search_path = public, pg_temp
 AS $$
 DECLARE
 show_backup_servers TEXT := '';
 backup_server_row RECORD;

 spaces TEXT := '   ';
 line TEXT := '-';
 divisor TEXT := ' | ';
 divisor_line TEXT := '';

 srv_fqdn_len INTEGER;
 srv_status_len INTEGER;

 BEGIN
  --
  -- This function generates a list with all backup servers
  -- defined in pgbackman
  --

  SELECT max(length(hostname))+max(length(domain_name))+1 AS len FROM backup_server INTO srv_fqdn_len;
  SELECT max(length(status)) AS len FROM backup_server INTO srv_status_len;

  divisor_line := rpad(line,5,line) || rpad(line,length(spaces),line) ||
		  rpad(line,srv_fqdn_len,line) || rpad(line,length(spaces),line) ||
  		  rpad(line,srv_status_len,line) || rpad(line,length(spaces),line) ||
		  rpad(line,30,line) || rpad(line,length(spaces),line) ||
                  E'\n';

  show_backup_servers := show_backup_servers || divisor_line;
  		     
  show_backup_servers := show_backup_servers ||
  		     	rpad('SrvID',5,' ') || divisor ||
			rpad('FQDN',srv_fqdn_len,' ') || divisor ||
			rpad('Status',srv_status_len,' ') || divisor ||
			rpad('Remarks',30,' ') || 
			E'\n';

  show_backup_servers := show_backup_servers || divisor_line;
  
   FOR backup_server_row IN (
   SELECT server_id,
          hostname,
          domain_name,
          status,
          remarks
   FROM backup_server
   ORDER BY hostname,domain_name,status
  ) LOOP
 
     show_backup_servers := show_backup_servers ||
     			   lpad(backup_server_row.server_id::text,5,'0') || divisor ||
			   rpad(backup_server_row.hostname || '.' || backup_server_row.domain_name, srv_fqdn_len,' ')|| divisor ||
			   rpad(backup_server_row.status, srv_status_len,' ')|| divisor ||
			   rpad(backup_server_row.remarks, 30,' ')|| 
			   E'\n';
			      
  END LOOP;

  show_backup_servers := show_backup_servers || divisor_line;

RETURN show_backup_servers;
 END;
$$;

ALTER FUNCTION show_backup_servers() OWNER TO pgbackman_user_rw;



-- ------------------------------------------------------------
-- Function: register_pgsql_node()
--
-- ------------------------------------------------------------

CREATE OR REPLACE FUNCTION register_pgsql_node(TEXT,TEXT,INTEGER,TEXT,CHARACTER VARYING,TEXT) RETURNS BOOLEAN
 LANGUAGE plpgsql 
 SECURITY INVOKER 
 SET search_path = public, pg_temp
 AS $$
 DECLARE
 
  hostname_ ALIAS FOR $1;
  domain_name_ ALIAS FOR $2;
  pgport_ ALIAS FOR $3; 
  admin_user_ ALIAS FOR $4;
  status_ ALIAS FOR $5;
  remarks_ ALIAS FOR $6;  

  node_cnt INTEGER;
 BEGIN

   IF domain_name_ = '' OR domain_name_ IS NULL THEN
    domain_name_ := get_default_pgsql_node_parameter('domain');
   END IF;

   IF pgport_ = 0 OR pgport_ IS NULL THEN
    pgport_ := get_default_pgsql_node_parameter('pgport')::INTEGER;
   END IF;

   IF admin_user_ = '' OR admin_user_ IS NULL THEN
    admin_user_ := get_default_pgsql_node_parameter('admin_user');
   END IF;

   IF status_ = '' OR status_ IS NULL THEN
    status_ := get_default_pgsql_node_parameter('pgsql_node_status');
   END IF;

   SELECT count(*) AS cnt FROM pgsql_node WHERE hostname = hostname_ AND domain_name = domain_name_ AND pgport = pgport_ AND admin_user = admin_user_ INTO node_cnt;

   IF node_cnt = 0 THEN     

    EXECUTE 'INSERT INTO pgsql_node (hostname,domain_name,pgport,admin_user,status,remarks) VALUES ($1,$2,$3,$4,$5,$6)'
    USING hostname_,
          domain_name_,
          pgport_,
          admin_user_,
          status_,
          remarks_;         

   ELSIF  node_cnt > 0 THEN

    EXECUTE 'UPDATE pgsql_node SET status = $5, remarks = $6 WHERE hostname = $1 AND domain_name = $2 AND pgport = $3 AND admin_user = $4'
    USING hostname_,
          domain_name_,
          pgport_,
          admin_user_,
          status_,
          remarks_;

   END IF;

   RETURN TRUE;
 EXCEPTION
  WHEN transaction_rollback THEN
   RAISE EXCEPTION 'Transaction rollback when updating pgsql_node';
   RETURN FALSE;
  WHEN syntax_error_or_access_rule_violation THEN
   RAISE EXCEPTION 'Syntax or access error when updating pgsql_node';
   RETURN FALSE;
  WHEN foreign_key_violation THEN
   RAISE EXCEPTION 'Caught foreign_key_violation when updating pgsql_node';
   RETURN FALSE;
  WHEN unique_violation THEN
   RAISE EXCEPTION 'Duplicate key value violates unique constraint when updating pgsql_node';
   RETURN FALSE;
END;
$$;

ALTER FUNCTION register_pgsql_node(TEXT,TEXT,INTEGER,TEXT,CHARACTER VARYING,TEXT) OWNER TO pgbackman_user_rw;


-- ------------------------------------------------------------
-- Function: delete_pgsql_node()
--
-- ------------------------------------------------------------

CREATE OR REPLACE FUNCTION delete_pgsql_node(TEXT) RETURNS BOOLEAN
 LANGUAGE plpgsql 
 SECURITY INVOKER 
 SET search_path = public, pg_temp
 AS $$
 DECLARE
 
  pgsql_node_ ALIAS FOR $1;
  node_id_ INTEGER;
 BEGIN

 SELECT node_id FROM pgsql_node WHERE pgsql_node_ = hostname || '.' || domain_name  INTO node_id_;

   IF node_id_ IS NOT NULL THEN    

    EXECUTE 'DELETE FROM pgsql_node WHERE node_id = $1'
    USING node_id_;

    RETURN TRUE;
   ELSE
    RAISE EXCEPTION 'PgSQL node with NodeID = % does not exist',node_id_ USING HINT = 'Please check the NodeID value you want to delete';
    RETURN FALSE;
   END IF; 

END;
$$;

ALTER FUNCTION delete_pgsql_node(TEXT) OWNER TO pgbackman_user_rw;


-- ------------------------------------------------------------
-- Function: show_pgsql_nodes()
--
-- ------------------------------------------------------------

CREATE OR REPLACE FUNCTION show_pgsql_nodes() RETURNS TEXT 
 LANGUAGE plpgsql 
 SECURITY INVOKER 
 SET search_path = public, pg_temp
 AS $$
 DECLARE
 show_pgsql_nodes TEXT := E'\n';
 pgsql_node_row RECORD;

 spaces TEXT := '   ';
 line TEXT := '-';
 divisor TEXT := ' | ';
 divisor_line TEXT := '';

 node_fqdn_len INTEGER;
 node_status_len INTEGER;
 node_admin_user_len INTEGER;

 BEGIN
  --
  -- This function generates a list with all backup servers
  -- defined in pgbackman
  --

  SELECT max(length(hostname || '.' || domain_name)) AS len FROM pgsql_node INTO node_fqdn_len;
  SELECT max(length(status)) AS len FROM pgsql_node INTO node_status_len;
  SELECT max(length(admin_user)) AS len FROM pgsql_node INTO node_admin_user_len;


  divisor_line := rpad(line,6,line) ||  rpad(line,length(spaces),line) ||
       		  rpad(line,node_fqdn_len,line) || rpad(line,length(spaces),line) ||
		  rpad(line,6,line) ||  rpad(line,length(spaces),line) ||
		  rpad(line,node_admin_user_len,line) ||  rpad(line,length(spaces),line) ||
  		  rpad(line,node_status_len,line) ||  rpad(line,length(spaces),line) ||
	          rpad(line,30,line) ||  rpad(line,length(spaces),line) ||
                  E'\n';

  show_pgsql_nodes := show_pgsql_nodes || divisor_line;
  		     
  show_pgsql_nodes := show_pgsql_nodes ||
  		     	rpad('NodeID',6,' ') || divisor ||
			rpad('FQDN',node_fqdn_len,' ') || divisor ||
			rpad('Pgport',6,' ') || divisor ||
			rpad('Admin',node_admin_user_len,' ') || divisor ||   
			rpad('Status',node_status_len,' ') || divisor ||
			rpad('Remarks',30,' ') || 
			E'\n';

  show_pgsql_nodes := show_pgsql_nodes || divisor_line;
  
   FOR pgsql_node_row IN (
   SELECT node_id,
          hostname,
          domain_name,
          pgport,
          admin_user,
          pg_version,
          status,
          remarks
   FROM pgsql_node
   ORDER BY hostname,domain_name,pgport,admin_user,status
  ) LOOP
 
     show_pgsql_nodes := show_pgsql_nodes ||
     			   lpad(pgsql_node_row.node_id::text,6,'0') || divisor ||
			   rpad(pgsql_node_row.hostname || '.' || pgsql_node_row.domain_name, node_fqdn_len,' ')|| divisor ||
			   rpad(pgsql_node_row.pgport::text, 6,' ')|| divisor ||
			   rpad(pgsql_node_row.admin_user, node_admin_user_len,' ')|| divisor ||
			   rpad(pgsql_node_row.status, node_status_len,' ')|| divisor ||
			   rpad(pgsql_node_row.remarks, 30,' ') ||
			   E'\n';
			      
  END LOOP;

  show_pgsql_nodes := show_pgsql_nodes || divisor_line;

RETURN show_pgsql_nodes;
 END;
$$;

ALTER FUNCTION show_pgsql_nodes() OWNER TO pgbackman_user_rw;


-- ------------------------------------------------------------
-- Function: register_backup_job()
--
-- ------------------------------------------------------------

CREATE OR REPLACE FUNCTION register_backup_job(TEXT,TEXT,TEXT,CHARACTER VARYING,CHARACTER VARYING,CHARACTER VARYING,CHARACTER VARYING,CHARACTER VARYING,CHARACTER VARYING,BOOLEAN,INTERVAL,INTEGER,TEXT,CHARACTER VARYING,TEXT) RETURNS BOOLEAN
 LANGUAGE plpgsql 
 SECURITY INVOKER 
 SET search_path = public, pg_temp
 AS $$
 DECLARE
 
  backup_server_ ALIAS FOR $1;
  pgsql_node_ ALIAS FOR $2;
  dbname_ ALIAS FOR $3; 
  minutes_cron_ ALIAS FOR $4;
  hours_cron_ ALIAS FOR $5;
  weekday_cron_ ALIAS FOR $6;  
  month_cron_ ALIAS FOR $7;
  day_month_cron_ ALIAS FOR $8;	  
  backup_code_ ALIAS FOR $9;
  encryption_ ALIAS FOR $10;
  retention_period_ ALIAS FOR $11;
  retention_redundancy_ ALIAS FOR $12;
  extra_parameters_ ALIAS FOR $13;
  job_status_ ALIAS FOR $14;
  remarks_ ALIAS FOR $15;

  backup_server_id_ INTEGER;
  pgsql_node_id_ INTEGER;

  backup_job_cnt INTEGER;

  backup_hours_interval TEXT;
  backup_minutes_interval TEXT;

 BEGIN

   IF hours_cron_ = '' OR hours_cron_ IS NULL THEN
    backup_hours_interval := get_default_pgsql_node_parameter('backup_hours_interval');
    hours_cron_ :=  get_hour_from_interval(backup_hours_interval)::TEXT;
   END IF;  

   IF minutes_cron_ = '' OR minutes_cron_ IS NULL THEN
    backup_minutes_interval := get_default_pgsql_node_parameter('backup_minutes_interval');
    minutes_cron_ := get_minutes_from_interval(backup_minutes_interval)::TEXT;
   END IF;

   IF weekday_cron_ = '' OR weekday_cron_ IS NULL THEN
    weekday_cron_ := get_default_pgsql_node_parameter('backup_weekday_cron');
   END IF;

   IF month_cron_ = '' OR month_cron_ IS NULL THEN
    month_cron_ := get_default_pgsql_node_parameter('backup_month_cron');
   END IF;

   IF day_month_cron_ = '' OR day_month_cron_ IS NULL THEN
    day_month_cron_ := get_default_pgsql_node_parameter('backup_day_month_cron');
   END IF;

   IF backup_code_ = '' OR backup_code_ IS NULL THEN
    backup_code_ :=  get_default_pgsql_node_parameter('backup_code');
   END IF;

   IF encryption_ IS NULL THEN
    encryption_ := get_default_pgsql_node_parameter('encryption');
   END IF;

   IF retention_period_ IS NULL THEN
    retention_period_ := get_default_pgsql_node_parameter('retention_period')::INTERVAL;
   END IF;
 
   IF retention_redundancy_ = 0 OR retention_redundancy_ IS NULL THEN
    retention_redundancy_ := get_default_pgsql_node_parameter('retention_redundancy')::INTEGER;
   END IF;

   IF extra_parameters_ = '' OR extra_parameters_ IS NULL THEN
    extra_parameters_ := get_default_pgsql_node_parameter('extra_parameters');
   END IF;
   
   IF job_status_ = '' OR job_status_ IS NULL THEN
    job_status_ := get_default_pgsql_node_parameter('backup_job_status');
   END IF;

   SELECT server_id FROM backup_server WHERE hostname || '.' || domain_name = backup_server_ INTO backup_server_id_;
   SELECT node_id FROM pgsql_node WHERE hostname || '.' || domain_name = pgsql_node_ INTO pgsql_node_id_;   

   IF backup_server_id_ IS NULL THEN
     RAISE EXCEPTION 'Backup server % does not exist',backup_server_ ;
     RETURN FALSE;
   ELSIF pgsql_node_id_ IS NULL THEN
     RAISE EXCEPTION 'pgsql node % does not exist',backup_server_ ;
     RETURN FALSE;
   END IF;

   SELECT count(*) AS cnt 
   FROM backup_job_definition 
   WHERE pgsql_node_id = pgsql_node_id_ 
   AND dbname = dbname_ 
   AND backup_code = backup_code_ 
   AND extra_parameters = extra_parameters_ 
   INTO backup_job_cnt;

   IF backup_job_cnt = 0 THEN     

    EXECUTE 'INSERT INTO backup_job_definition (backup_server_id,
						pgsql_node_id,
						dbname,
						minutes_cron,
						hours_cron,
						weekday_cron,
						month_cron,
						day_month_cron,
						backup_code,
						encryption,
						retention_period,
						retention_redundancy,
						extra_parameters,
						job_status,
						remarks)
	     VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15)'
    USING backup_server_id_,
	  pgsql_node_id_,
	  dbname_,
	  minutes_cron_,
	  hours_cron_,
	  weekday_cron_,
	  month_cron_,
	  day_month_cron_,
	  backup_code_,
	  encryption_,
	  retention_period_,
	  retention_redundancy_,
	  extra_parameters_,
	  job_status_,
	  remarks_;         

   ELSIF backup_job_cnt > 0 THEN

    EXECUTE 'UPDATE backup_job_definition 
    	     SET minutes_cron = $4, 
	     	 hours_cron = $5,
		 weekday_cron = $6,
		 month_cron = $7,
		 day_month_cron = $8,
		 encryption = $10,
		 retention_period = $11,
		 retention_redundancy = $12,
		 job_status = $14,
		 remarks = $15
	     WHERE  backup_server_id = $1
	     AND pgsql_node_id = $2
	     AND dbname = $3
	     AND backup_code = $9 
	     AND extra_parameters = $13'
    USING backup_server_id_,
	  pgsql_node_id_,
	  dbname_,
	  minutes_cron_,
	  hours_cron_,
	  weekday_cron_,
	  month_cron_,
	  day_month_cron_,
	  backup_code_,
	  encryption_,
	  retention_period_,
	  retention_redundancy_,
	  extra_parameters_,
	  job_status_,
	  remarks_;         

   END IF;

   RETURN TRUE;
 EXCEPTION
  WHEN transaction_rollback THEN
   RAISE EXCEPTION 'Transaction rollback when updating pgsql_node';
   RETURN FALSE;
  WHEN syntax_error_or_access_rule_violation THEN
   RAISE EXCEPTION 'Syntax or access error when updating pgsql_node';
   RETURN FALSE;
  WHEN foreign_key_violation THEN
   RAISE EXCEPTION 'Caught foreign_key_violation when updating pgsql_node';
   RETURN FALSE;
  WHEN unique_violation THEN
   RAISE EXCEPTION 'Duplicate key value violates unique constraint when updating pgsql_node';
   RETURN FALSE;
END;
$$;

ALTER FUNCTION register_backup_job(TEXT,TEXT,TEXT,CHARACTER VARYING,CHARACTER VARYING,CHARACTER VARYING,CHARACTER VARYING,CHARACTER VARYING,CHARACTER VARYING,BOOLEAN,INTERVAL,INTEGER,TEXT,CHARACTER VARYING,TEXT) OWNER TO pgbackman_user_rw;


-- ############################################################3
--
-- Function show_backup_server_job_definitions()
--
-- ############################################################

CREATE OR REPLACE FUNCTION show_backup_server_job_definitions (TEXT) RETURNS TEXT 
 LANGUAGE plpgsql 
 SECURITY DEFINER 
 SET search_path = public, pg_temp
 AS $$
 DECLARE
  backup_server_ ALIAS FOR $1;
  server_id_ INTEGER;
  
  show_backup_jobs_def TEXT := E'\n';
  backup_def_row RECORD;

  spaces TEXT := '   ';
  line TEXT := '-';
  divisor TEXT := ' | ';
  divisor_line TEXT := '';

  pgsql_node_len INTEGER := 0;
  dbname_len INTEGER := 0;
  time_schedule_len INTEGER := 0;
  backup_code_len INTEGER := 0;
  encryption_len INTEGER := 0;
  retention_len INTEGER := 0;
  extra_parameters_len INTEGER := 0;
  job_status_len INTEGER := 0;

 BEGIN

  --
  -- This function generates a view of all backup definitions
  -- for a backup server.
  --

  SELECT server_id FROM backup_server WHERE backup_server_ = hostname || '.' || domain_name INTO server_id_;

  IF server_id_ IS NULL THEN
    RAISE EXCEPTION 'Backup server: % does not exist in this system', backup_server_;
  END IF;

  SELECT max(length(get_pgsql_node_fqdn(pgsql_node_id))) FROM backup_job_definition WHERE backup_server_id = server_id_ INTO pgsql_node_len;
  SELECT max(length(dbname)) FROM backup_job_definition WHERE backup_server_id = server_id_ INTO dbname_len;	
  SELECT max(length(minutes_cron || ' ' || hours_cron || ' ' || 
  	 weekday_cron || ' ' || month_cron || ' ' || 
	 day_month_cron)) FROM backup_job_definition WHERE backup_server_id = server_id_ INTO time_schedule_len;

  SELECT max(length(backup_code)) FROM backup_job_definition WHERE backup_server_id = server_id_ INTO backup_code_len;
  SELECT max(length(encryption::text)) FROM backup_job_definition WHERE backup_server_id = server_id_ INTO encryption_len;
  SELECT max(length(retention_period::text || ' (' || retention_redundancy::text || ')')) FROM backup_job_definition WHERE backup_server_id = server_id_ INTO retention_len;
  SELECT max(length(extra_parameters)) FROM backup_job_definition WHERE backup_server_id = server_id_ INTO extra_parameters_len;
  SELECT max(length(job_status)) FROM backup_job_definition WHERE backup_server_id = server_id_ INTO job_status_len;	

  IF extra_parameters_len < 11 THEN
   extra_parameters_len := 11;
  END IF;

  divisor_line := rpad(line,8,line) || rpad(line,length(spaces),line) ||
  	       	  rpad(line,pgsql_node_len,line) || rpad(line,length(spaces),line) ||
  	       	  rpad(line,dbname_len,line) || rpad(line,length(spaces),line) ||
		  rpad(line,time_schedule_len,line) || rpad(line,length(spaces),line) ||
		  rpad(line,backup_code_len,line) || rpad(line,length(spaces),line) ||
		  rpad(line,10,line) || rpad(line,length(spaces),line) ||
		  rpad(line,retention_len,line) || rpad(line,length(spaces),line) ||
		  rpad(line,job_status_len,line) || rpad(line,length(spaces),line) ||
		  rpad(line,extra_parameters_len,line) || rpad(line,length(spaces),line) ||
                  E'\n';

  show_backup_jobs_def := show_backup_jobs_def || divisor_line;
  show_backup_jobs_def := show_backup_jobs_def || 'BACKUP SERVER: ' || '[' || server_id_ || '] ' || backup_server_ || E'\n';
  show_backup_jobs_def := show_backup_jobs_def || divisor_line;  
  
  show_backup_jobs_def := show_backup_jobs_def || 
  		       	  rpad('DefID',8,' ') || divisor ||
			  rpad('PgSQL node',pgsql_node_len,' ') || divisor ||
			  rpad('DBname',dbname_len,' ') || divisor ||
			  rpad('Schedule',time_schedule_len,' ') || divisor ||   
			  rpad('Code',backup_code_len,' ') || divisor ||
			  rpad('Encryption',10,' ') ||  divisor ||
			  rpad('Retention',retention_len,' ') || divisor ||
			  rpad('status',job_status_len,' ') || divisor ||
  			  rpad('Parameters',extra_parameters_len,' ') || 
			  E'\n';

  show_backup_jobs_def := show_backup_jobs_def || divisor_line;  

 FOR backup_def_row IN (
   SELECT job_id,
   	  get_pgsql_node_fqdn(pgsql_node_id) AS pgsql_node,
          dbname,
	  minutes_cron || ' ' || hours_cron || ' ' || weekday_cron || ' ' || month_cron || ' ' || day_month_cron As schedule,
	  backup_code,
	  encryption::TEXT,
	  retention_period::TEXT || ' (' || retention_redundancy::TEXT || ')' AS retention,
	  job_status,
	  extra_parameters
   FROM backup_job_definition
   WHERE backup_server_id = server_id_
   ORDER BY pgsql_node,dbname,backup_code,job_status
  ) LOOP
 
     show_backup_jobs_def := show_backup_jobs_def ||
     			   lpad(backup_def_row.job_id::text,8,'0') || divisor ||
			   rpad(backup_def_row.pgsql_node,pgsql_node_len,' ') || divisor ||
			   rpad(backup_def_row.dbname,dbname_len,' ')|| divisor ||
			   rpad(backup_def_row.schedule,time_schedule_len,' ') || divisor ||
			   rpad(backup_def_row.backup_code,backup_code_len,' ') || divisor ||
			   rpad(backup_def_row.encryption,10,' ') || divisor ||
			   rpad(backup_def_row.retention,retention_len,' ') || divisor ||
			   rpad(backup_def_row.job_status,job_status_len,' ')|| divisor ||
			   rpad(backup_def_row.extra_parameters,extra_parameters_len,' ') ||
			   E'\n';
			      
  END LOOP;

  show_backup_jobs_def := show_backup_jobs_def || divisor_line;  

 RETURN show_backup_jobs_def;
 END;
$$;

ALTER FUNCTION show_backup_server_job_definitions(TEXT) OWNER TO pgbackman_user_rw;


-- ############################################################3
--
-- Function show_pgsql_node_job_definitions()
--
-- ############################################################

CREATE OR REPLACE FUNCTION show_pgsql_node_job_definitions (TEXT) RETURNS TEXT 
 LANGUAGE plpgsql 
 SECURITY DEFINER 
 SET search_path = public, pg_temp
 AS $$
 DECLARE
  pgsql_node_ ALIAS FOR $1;
  pgsql_node_id_ INTEGER;
  
  show_backup_jobs_def TEXT := E'\n';
  backup_def_row RECORD;

  spaces TEXT := '   ';
  line TEXT := '-';
  divisor TEXT := ' | ';
  divisor_line TEXT := '';

  backup_server_len INTEGER := 0;
  dbname_len INTEGER := 0;
  time_schedule_len INTEGER := 0;
  backup_code_len INTEGER := 0;
  encryption_len INTEGER := 0;
  retention_len INTEGER := 0;
  extra_parameters_len INTEGER := 0;
  job_status_len INTEGER := 0;

 BEGIN

  --
  -- This function generates a view of all backup definitions
  -- for a backup server.
  --

  SELECT node_id FROM pgsql_node WHERE pgsql_node_ = hostname || '.' || domain_name INTO pgsql_node_id_;

  IF pgsql_node_id_ IS NULL THEN
    RAISE EXCEPTION 'PgSQL node: % does not exist in this system', pgsql_node_;
  END IF;

  SELECT max(length(get_backup_server_fqdn(backup_server_id))) FROM backup_job_definition WHERE pgsql_node_id = pgsql_node_id_ INTO backup_server_len;
  SELECT max(length(dbname)) FROM backup_job_definition WHERE pgsql_node_id = pgsql_node_id_ INTO dbname_len;	
  SELECT max(length(minutes_cron || ' ' || hours_cron || ' ' || 
  	 weekday_cron || ' ' || month_cron || ' ' || 
	 day_month_cron)) FROM backup_job_definition WHERE pgsql_node_id = pgsql_node_id_ INTO time_schedule_len;

  SELECT max(length(backup_code)) FROM backup_job_definition WHERE pgsql_node_id = pgsql_node_id_ INTO backup_code_len;
  SELECT max(length(encryption::text)) FROM backup_job_definition WHERE pgsql_node_id = pgsql_node_id_ INTO encryption_len;
  SELECT max(length(retention_period::text || ' (' || retention_redundancy::text || ')')) FROM backup_job_definition WHERE pgsql_node_id = pgsql_node_id_ INTO retention_len;
  SELECT max(length(extra_parameters)) FROM backup_job_definition WHERE pgsql_node_id = pgsql_node_id_ INTO extra_parameters_len;
  SELECT max(length(job_status)) FROM backup_job_definition WHERE pgsql_node_id = pgsql_node_id_ INTO job_status_len;	

  IF extra_parameters_len < 11 THEN
   extra_parameters_len := 11;
  END IF;

  divisor_line := rpad(line,8,line) || rpad(line,length(spaces),line) ||
  	       	  rpad(line,backup_server_len,line) || rpad(line,length(spaces),line) ||
  	       	  rpad(line,dbname_len,line) || rpad(line,length(spaces),line) ||
		  rpad(line,time_schedule_len,line) || rpad(line,length(spaces),line) ||
		  rpad(line,backup_code_len,line) || rpad(line,length(spaces),line) ||
		  rpad(line,10,line) || rpad(line,length(spaces),line) ||
		  rpad(line,retention_len,line) || rpad(line,length(spaces),line) ||
		  rpad(line,job_status_len,line) || rpad(line,length(spaces),line) ||
		  rpad(line,extra_parameters_len,line) || rpad(line,length(spaces),line) ||
                  E'\n';

  show_backup_jobs_def := show_backup_jobs_def || divisor_line;
  show_backup_jobs_def := show_backup_jobs_def || 'PgSQL NODE: ' || '[' || pgsql_node_id_ || '] ' || pgsql_node_ || E'\n';
  show_backup_jobs_def := show_backup_jobs_def || divisor_line;  
  
  show_backup_jobs_def := show_backup_jobs_def || 
  		       	  rpad('DefID',8,' ') || divisor ||
			  rpad('Backup server',backup_server_len,' ') || divisor ||
			  rpad('DBname',dbname_len,' ') || divisor ||
			  rpad('Schedule',time_schedule_len,' ') || divisor ||   
			  rpad('Code',backup_code_len,' ') || divisor ||
			  rpad('Encryption',10,' ') ||  divisor ||
			  rpad('Retention',retention_len,' ') || divisor ||
			  rpad('status',job_status_len,' ') || divisor ||
  			  rpad('Parameters',extra_parameters_len,' ') || 
			  E'\n';

  show_backup_jobs_def := show_backup_jobs_def || divisor_line;  

 FOR backup_def_row IN (
   SELECT job_id,
   	  get_backup_server_fqdn(backup_server_id) AS backup_server,
          dbname,
	  minutes_cron || ' ' || hours_cron || ' ' || weekday_cron || ' ' || month_cron || ' ' || day_month_cron As schedule,
	  backup_code,
	  encryption::TEXT,
	  retention_period::TEXT || ' (' || retention_redundancy::TEXT || ')' AS retention,
	  job_status,
	  extra_parameters
   FROM backup_job_definition
   WHERE pgsql_node_id = pgsql_node_id_
   ORDER BY backup_server,dbname,backup_code,job_status
  ) LOOP
 
     show_backup_jobs_def := show_backup_jobs_def ||
     			   lpad(backup_def_row.job_id::text,8,'0') || divisor ||
			   rpad(backup_def_row.backup_server,backup_server_len,' ') || divisor ||
			   rpad(backup_def_row.dbname,dbname_len,' ')|| divisor ||
			   rpad(backup_def_row.schedule,time_schedule_len,' ') || divisor ||
			   rpad(backup_def_row.backup_code,backup_code_len,' ') || divisor ||
			   rpad(backup_def_row.encryption,10,' ') || divisor ||
			   rpad(backup_def_row.retention,retention_len,' ') || divisor ||
			   rpad(backup_def_row.job_status,job_status_len,' ')|| divisor ||
			   rpad(backup_def_row.extra_parameters,extra_parameters_len,' ') ||
			   E'\n';
			      
  END LOOP;

  show_backup_jobs_def := show_backup_jobs_def || divisor_line;  

 RETURN show_backup_jobs_def;
 END;
$$;

ALTER FUNCTION show_pgsql_node_job_definitions(TEXT) OWNER TO pgbackman_user_rw;


-- ############################################################3
--
-- Function show_database_job_definitions()
--
-- ############################################################

CREATE OR REPLACE FUNCTION show_database_job_definitions (TEXT) RETURNS TEXT 
 LANGUAGE plpgsql 
 SECURITY DEFINER 
 SET search_path = public, pg_temp
 AS $$
 DECLARE
  dbname_ ALIAS FOR $1;
 
  show_backup_jobs_def TEXT := E'\n';
  backup_def_row RECORD;

  spaces TEXT := '   ';
  line TEXT := '-';
  divisor TEXT := ' | ';
  divisor_line TEXT := '';

  backup_server_len INTEGER := 0;
  pgsql_node_len INTEGER := 0;
  time_schedule_len INTEGER := 0;
  backup_code_len INTEGER := 0;
  encryption_len INTEGER := 0;
  retention_len INTEGER := 0;
  extra_parameters_len INTEGER := 0;
  job_status_len INTEGER := 0;

  dbname_cnt INTEGER := 0;

 BEGIN

  --
  -- This function generates a view of all backup definitions
  -- for a backup server.
  --

  SELECT count(*) FROM backup_job_definition WHERE dbname = dbname_ INTO dbname_cnt;

  IF dbname_cnt = 0 THEN
    RAISE EXCEPTION 'Database: % does not exist in this system', dbname_;
  END IF;

  SELECT max(length(get_backup_server_fqdn(backup_server_id))) FROM backup_job_definition WHERE dbname = dbname_ INTO backup_server_len;
  SELECT max(length(get_pgsql_node_fqdn(pgsql_node_id))) FROM backup_job_definition WHERE dbname = dbname_ INTO pgsql_node_len;
  SELECT max(length(minutes_cron || ' ' || hours_cron || ' ' || 
  	 weekday_cron || ' ' || month_cron || ' ' || 
	 day_month_cron)) FROM backup_job_definition WHERE dbname = dbname_ INTO time_schedule_len;

  SELECT max(length(backup_code)) FROM backup_job_definition WHERE dbname = dbname_ INTO backup_code_len;
  SELECT max(length(encryption::text)) FROM backup_job_definition WHERE dbname = dbname_ INTO encryption_len;
  SELECT max(length(retention_period::text || ' (' || retention_redundancy::text || ')')) FROM backup_job_definition WHERE dbname = dbname_ INTO retention_len;
  SELECT max(length(extra_parameters)) FROM backup_job_definition WHERE dbname = dbname_ INTO extra_parameters_len;
  SELECT max(length(job_status)) FROM backup_job_definition WHERE dbname = dbname_ INTO job_status_len;	

  IF extra_parameters_len < 11 THEN
   extra_parameters_len := 11;
  END IF;

  divisor_line := rpad(line,8,line) || rpad(line,length(spaces),line) ||
  	       	  rpad(line,backup_server_len,line) || rpad(line,length(spaces),line) ||
  	       	  rpad(line,pgsql_node_len,line) || rpad(line,length(spaces),line) ||
		  rpad(line,time_schedule_len,line) || rpad(line,length(spaces),line) ||
		  rpad(line,backup_code_len,line) || rpad(line,length(spaces),line) ||
		  rpad(line,10,line) || rpad(line,length(spaces),line) ||
		  rpad(line,retention_len,line) || rpad(line,length(spaces),line) ||
		  rpad(line,job_status_len,line) || rpad(line,length(spaces),line) ||
		  rpad(line,extra_parameters_len,line) || rpad(line,length(spaces),line) ||
                  E'\n';

  show_backup_jobs_def := show_backup_jobs_def || divisor_line;
  show_backup_jobs_def := show_backup_jobs_def || 'DATABASE: ' || dbname_ || E'\n';
  show_backup_jobs_def := show_backup_jobs_def || divisor_line;  
  
  show_backup_jobs_def := show_backup_jobs_def || 
  		       	  rpad('DefID',8,' ') || divisor ||
			  rpad('Backup server',backup_server_len,' ') || divisor ||
			  rpad('PgSQL node',pgsql_node_len,' ') || divisor ||
			  rpad('Schedule',time_schedule_len,' ') || divisor ||   
			  rpad('Code',backup_code_len,' ') || divisor ||
			  rpad('Encryption',10,' ') ||  divisor ||
			  rpad('Retention',retention_len,' ') || divisor ||
			  rpad('status',job_status_len,' ') || divisor ||
  			  rpad('Parameters',extra_parameters_len,' ') || 
			  E'\n';

  show_backup_jobs_def := show_backup_jobs_def || divisor_line;  

 FOR backup_def_row IN (
   SELECT job_id,
   	  get_backup_server_fqdn(backup_server_id) AS backup_server,
          get_pgsql_node_fqdn(pgsql_node_id) AS pgsql_node,
	  minutes_cron || ' ' || hours_cron || ' ' || weekday_cron || ' ' || month_cron || ' ' || day_month_cron As schedule,
	  backup_code,
	  encryption::TEXT,
	  retention_period::TEXT || ' (' || retention_redundancy::TEXT || ')' AS retention,
	  job_status,
	  extra_parameters
   FROM backup_job_definition
   WHERE dbname = dbname_
   ORDER BY backup_server,pgsql_node,backup_code,job_status
  ) LOOP
 
     show_backup_jobs_def := show_backup_jobs_def ||
     			   lpad(backup_def_row.job_id::text,8,'0') || divisor ||
			   rpad(backup_def_row.backup_server,backup_server_len,' ') || divisor ||
			   rpad(backup_def_row.pgsql_node,pgsql_node_len,' ')|| divisor ||
			   rpad(backup_def_row.schedule,time_schedule_len,' ') || divisor ||
			   rpad(backup_def_row.backup_code,backup_code_len,' ') || divisor ||
			   rpad(backup_def_row.encryption,10,' ') || divisor ||
			   rpad(backup_def_row.retention,retention_len,' ') || divisor ||
			   rpad(backup_def_row.job_status,job_status_len,' ')|| divisor ||
			   rpad(backup_def_row.extra_parameters,extra_parameters_len,' ') ||
			   E'\n';
			      
  END LOOP;

  show_backup_jobs_def := show_backup_jobs_def || divisor_line;  

 RETURN show_backup_jobs_def;
 END;
$$;

ALTER FUNCTION show_database_job_definitions(TEXT) OWNER TO pgbackman_user_rw;



-- ------------------------------------------------------------
-- Function: get_default_backup_server_parameter()
--
-- ------------------------------------------------------------

CREATE OR REPLACE FUNCTION get_default_backup_server_parameter(TEXT) RETURNS TEXT 
 LANGUAGE plpgsql 
 SECURITY INVOKER 
 SET search_path = public, pg_temp
 AS $$
 DECLARE
 parameter_ ALIAS FOR $1; 
 value_ TEXT := '';

 BEGIN
  --
  -- This function returns the default value for a configuration parameter
  --

  SELECT value from backup_server_default_config WHERE parameter = parameter_ INTO value_;

  IF value_ IS NULL THEN
    RAISE EXCEPTION 'Parameter: % does not exist in this system',parameter_;
  END IF;

  RETURN value_;
 END;
$$;

ALTER FUNCTION get_default_backup_server_parameter(TEXT) OWNER TO pgbackman_user_rw;


-- ------------------------------------------------------------
-- Function: get_default_backup_server_parameter()
--
-- ------------------------------------------------------------

CREATE OR REPLACE FUNCTION get_backup_server_parameter(INTEGER,TEXT) RETURNS TEXT 
 LANGUAGE plpgsql 
 SECURITY INVOKER 
 SET search_path = public, pg_temp
 AS $$
 DECLARE
 server_id_ ALIAS FOR $1;
 parameter_ ALIAS FOR $2; 
 value_ TEXT := '';

 BEGIN
  --
  -- This function returns the default value for a configuration parameter
  --

  SELECT value from backup_server_config WHERE server_id = server_id_ AND parameter = parameter_ INTO value_;

  IF value_ IS NULL THEN
    RAISE EXCEPTION 'Parameter: % for server % does not exist in this system',parameter_,server_id_;
  END IF;

  RETURN value_;
 END;
$$;

ALTER FUNCTION get_backup_server_parameter(INTEGER,TEXT) OWNER TO pgbackman_user_rw;

-- ------------------------------------------------------------
-- Function: get_default_pgsql_node_parameter()
--
-- ------------------------------------------------------------

CREATE OR REPLACE FUNCTION get_default_pgsql_node_parameter(TEXT) RETURNS TEXT 
 LANGUAGE plpgsql 
 SECURITY INVOKER 
 SET search_path = public, pg_temp
 AS $$
 DECLARE
 parameter_ ALIAS FOR $1; 
 value_ TEXT := '';

 BEGIN
  --
  -- This function returns the default value for a configuration parameter
  --

  SELECT value from pgsql_node_default_config WHERE parameter = parameter_ INTO value_;

  IF value_ IS NULL THEN
    RAISE EXCEPTION 'Parameter: % does not exist in this system',parameter_;
  END IF;

  RETURN value_;
 END;
$$;

ALTER FUNCTION get_default_pgsql_node_parameter(TEXT) OWNER TO pgbackman_user_rw;


-- ------------------------------------------------------------
-- Function: get_pgsql_node_parameter()
--
-- ------------------------------------------------------------

CREATE OR REPLACE FUNCTION get_pgsql_node_parameter(INTEGER,TEXT) RETURNS TEXT 
 LANGUAGE plpgsql 
 SECURITY INVOKER 
 SET search_path = public, pg_temp
 AS $$
 DECLARE
 node_id_ ALIAS FOR $1;
 parameter_ ALIAS FOR $2; 
 value_ TEXT := '';

 BEGIN
  --
  -- This function returns the value for a configuration parameter for a pgsql_node
  --

  SELECT value from pgsql_node_config WHERE node_id = node_id_ AND parameter = parameter_ INTO value_;

  IF value_ IS NULL THEN
    RAISE EXCEPTION 'Parameter: % for server % does not exist in this system',parameter_,node_id_;
  END IF;

  RETURN value_;
 END;
$$;

ALTER FUNCTION get_pgsql_node_parameter(INTEGER,TEXT) OWNER TO pgbackman_user_rw;

-- ------------------------------------------------------------
-- Function: get_hour_from_interval()
--
-- ------------------------------------------------------------

CREATE OR REPLACE FUNCTION get_hour_from_interval(TEXT) RETURNS TEXT
 LANGUAGE plpgsql 
 SECURITY INVOKER 
 SET search_path = public, pg_temp
 AS $$
 DECLARE
 hour_interval_ ALIAS FOR $1; 
 
 hour_from INTEGER;
 hour_to INTEGER;
 value_ INTEGER;

 BEGIN
  --
  -- This function returns a value from an interval defined as 'Num1-Num2'
  --

   SELECT substr(hour_interval_,1,strpos(hour_interval_,'-')-1)::integer INTO hour_from;
   SELECT substr(hour_interval_,strpos(hour_interval_,'-')+1,length(hour_interval_)-strpos(hour_interval_,'-'))::INTEGER INTO hour_to;

   IF hour_from < 0 OR hour_from > 23 THEN
     RAISE EXCEPTION 'Hour % is not an allowed value',hour_from USING HINT = 'Allowed values: 00 to 23';
   ELSIF hour_to < 0 OR hour_to > 23 THEN
     RAISE EXCEPTION 'Hour % is not an allowed value',hour_to USING HINT = 'Allowed values: 00 to 23';
   END IF;

   SELECT round(random()*(hour_to-hour_from))+hour_from::INTEGER INTO value_;

   RETURN lpad(value_::TEXT,2,'0');

 END;
$$;

ALTER FUNCTION get_hour_from_interval(TEXT) OWNER TO pgbackman_user_rw;


-- ------------------------------------------------------------
-- Function: get_minute_from_interval()
--
-- ------------------------------------------------------------

CREATE OR REPLACE FUNCTION get_minute_from_interval(TEXT) RETURNS TEXT
 LANGUAGE plpgsql 
 SECURITY INVOKER 
 SET search_path = public, pg_temp
 AS $$
 DECLARE
 minute_interval_ ALIAS FOR $1; 
 
 minute_from INTEGER;
 minute_to INTEGER;
 value_ INTEGER;

 BEGIN
  --
  -- This function returns value from an interval defined as 'Num1-Num2'
  --

   SELECT substr(minute_interval_,1,strpos(minute_interval_,'-')-1)::integer INTO minute_from;
   SELECT substr(minute_interval_,strpos(minute_interval_,'-')+1,length(minute_interval_)-strpos(minute_interval_,'-'))::INTEGER INTO minute_to;

   IF minute_from < 0 OR minute_from > 59 THEN
     RAISE EXCEPTION 'Minute % is not an allowed value',minute_from USING HINT = 'Allowed values: 00 to 59';
   ELSIF minute_to < 0 OR minute_to > 59 THEN
     RAISE EXCEPTION 'Minute % is not an allowed value',minute_to USING HINT = 'Allowed values: 00 to 59';
   END IF;

   SELECT round(random()*(minute_to-minute_from))+minute_from::INTEGER INTO value_;

   RETURN lpad(value_::TEXT,2,'0');

 END;
$$;

ALTER FUNCTION get_minute_from_interval(TEXT) OWNER TO pgbackman_user_rw;

-- ------------------------------------------------------------
-- Function: get_backup_server_fqdn()
--
-- ------------------------------------------------------------

CREATE OR REPLACE FUNCTION get_backup_server_fqdn(INTEGER) RETURNS TEXT 
 LANGUAGE plpgsql 
 SECURITY INVOKER 
 SET search_path = public, pg_temp
 AS $$
 DECLARE
 parameter_ ALIAS FOR $1; 
 value_ TEXT := '';

 BEGIN
  --
  -- This function returns the fqdn of a backup server
  --

  SELECT hostname || '.' || domain_name from backup_server WHERE server_id = parameter_ INTO value_;

  IF value_ IS NULL THEN
    RAISE EXCEPTION 'Backup server with ID: % does not exist in this system',parameter_;
  END IF;

  RETURN value_;
 END;
$$;

ALTER FUNCTION get_backup_server_fqdn(INTEGER) OWNER TO pgbackman_user_rw;

-- ------------------------------------------------------------
-- Function: get_pgsql_node_fqdn()
--
-- ------------------------------------------------------------

CREATE OR REPLACE FUNCTION get_pgsql_node_fqdn(INTEGER) RETURNS TEXT 
 LANGUAGE plpgsql 
 SECURITY INVOKER 
 SET search_path = public, pg_temp
 AS $$
 DECLARE
 parameter_ ALIAS FOR $1; 
 value_ TEXT := '';

 BEGIN
  --
  -- This function returns the fqdn of a pgsql node
  --

  SELECT hostname || '.' || domain_name from pgsql_node WHERE node_id = parameter_ INTO value_;

  IF value_ IS NULL THEN
    RAISE EXCEPTION 'PgSQL node with ID: % does not exist in this system',parameter_;
  END IF;

  RETURN value_;
 END;
$$;

ALTER FUNCTION get_pgsql_node_fqdn(INTEGER) OWNER TO pgbackman_user_rw;


CREATE OR REPLACE FUNCTION get_listen_channel_names(INTEGER) RETURNS SETOF TEXT 
 LANGUAGE sql
 SECURITY INVOKER 
 SET search_path = public, pg_temp
 AS $$
  SELECT 'channel_BS' || $1 || '_PG' || node_id from pgsql_node
$$;


COMMIT;