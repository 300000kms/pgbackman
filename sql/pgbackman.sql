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

ALTER TABLE pgsql_node ADD PRIMARY KEY (hostname,domain_name,pgport);
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
-- @def_id
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

  def_id SERIAL UNIQUE,
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
-- @def_id
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

  bck_id BIGSERIAL,
  registered TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
  def_id INTEGER NOT NULL,
  backup_server_id INTEGER NOT NULL,
  pgsql_node_id INTEGER NOT NULL,
  dbname TEXT NOT NULL,
  started TIMESTAMP WITH TIME ZONE,
  finished TIMESTAMP WITH TIME ZONE,
  duration INTERVAL,
  pg_dump_file TEXT,
  pg_dump_file_size BIGINT,
  pg_dump_log_file TEXT,
  pg_dump_roles_file TEXT,
  pg_dump_roles_file_size BIGINT,
  pg_dump_roles_log_file TEXT,
  pg_dump_dbconfig_file TEXT,
  pg_dump_dbconfig_file_size BIGINT,
  pg_dump_dbconfig_log_file TEXT,
  global_log_file TEXT NOT NULL,
  execution_status TEXT
);

ALTER TABLE backup_job_catalog ADD PRIMARY KEY (bck_id);
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
    ADD FOREIGN KEY (def_id) REFERENCES  backup_job_definition (def_id) MATCH FULL ON DELETE RESTRICT;

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
INSERT INTO backup_code (code,description) VALUES ('CLUSTER','Full backup of the database cluster.');
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
INSERT INTO backup_server_default_config (parameter,value,description) VALUES ('pgbackman_dump','/usr/bin/pgbackman_dump','Program used to take backup dumps');
INSERT INTO backup_server_default_config (parameter,value,description) VALUES ('admin_user','postgres','postgreSQL admin user');
INSERT INTO backup_server_default_config (parameter,value,description) VALUES ('pgsql_bin_9.3','/usr/pgsql-9.3/bin','postgreSQL 9.3 bin directory');
INSERT INTO backup_server_default_config (parameter,value,description) VALUES ('pgsql_bin_9.2','/usr/pgsql-9.2/bin','postgreSQL 9.2 bin directory');
INSERT INTO backup_server_default_config (parameter,value,description) VALUES ('pgsql_bin_9.1','/usr/pgsql-9.1/bin','postgreSQL 9.1 bin directory');
INSERT INTO backup_server_default_config (parameter,value,description) VALUES ('pgsql_bin_9.0','/usr/pgsql-9.0/bin','postgreSQL 9.0 bin directory');
INSERT INTO backup_server_default_config (parameter,value,description) VALUES ('pgsql_bin_8.4','/usr/pgsql-8.4/bin','postgreSQL 8.4 bin directory');


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
INSERT INTO pgsql_node_default_config (parameter,value,description) VALUES ('logs_email','example@example.org','E-mail to send logs');



-- ------------------------------------------------------------
-- Function: update_backup_server_configuration()
--
-- ------------------------------------------------------------

CREATE OR REPLACE FUNCTION notify_pgsql_nodes_updated() RETURNS TRIGGER
 LANGUAGE plpgsql 
 SECURITY INVOKER 
 SET search_path = public, pg_temp
 AS $$
 BEGIN
  PERFORM pg_notify('channel_pgsql_nodes_updated','PgSQL node changed');
 
  RETURN NULL;
END;
$$;

ALTER FUNCTION notify_pgsql_nodes_updated() OWNER TO pgbackman_user_rw;

CREATE TRIGGER notify_pgsql_nodes_updated AFTER INSERT OR DELETE
    ON pgsql_node FOR EACH ROW
    EXECUTE PROCEDURE notify_pgsql_nodes_updated();


-- ------------------------------------------------------------
-- Function: update_backup_server_configuration()
--
-- ------------------------------------------------------------

CREATE OR REPLACE FUNCTION update_backup_server_configuration() RETURNS TRIGGER
 LANGUAGE plpgsql 
 SECURITY INVOKER 
 SET search_path = public, pg_temp
 AS $$
 BEGIN

  EXECUTE 'INSERT INTO backup_server_config (server_id,parameter,value,description) 
  	   SELECT $1,parameter,value,description FROM backup_server_default_config'
  USING NEW.server_id;

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
  	   SELECT $1,parameter,replace(replace(replace(value,''%%pgnode%%'',$2),''.'',''_''),''cron_d'',''cron.d''),description FROM pgsql_node_default_config'
  USING NEW.node_id,
  	NEW.hostname || '.' || NEW.domain_name;

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

CREATE OR REPLACE FUNCTION update_job_queue(INTEGER,INTEGER) RETURNS BOOLEAN
 LANGUAGE plpgsql 
 SECURITY INVOKER 
 SET search_path = public, pg_temp
 AS $$
 DECLARE
  backup_server_id_ ALIAS FOR $1;
  pgsql_node_id_ ALIAS FOR $2;

  srv_cnt INTEGER := -1;
 BEGIN

  SELECT count(*) FROM job_queue WHERE backup_server_id = backup_server_id_ AND pgsql_node_id = pgsql_node_id_ AND is_assigned IS FALSE INTO srv_cnt;
 
  IF srv_cnt = 0 THEN

   EXECUTE 'INSERT INTO job_queue (backup_server_id,pgsql_node_id,is_assigned) VALUES ($1,$2,FALSE)'
   USING backup_server_id_,
         pgsql_node_id_;

   PERFORM pg_notify('channel_bs' || backup_server_id_ || '_pg' || pgsql_node_id_,'Backup job inserted after crontab generation error');
   RETURN TRUE;  
  ELSE
   RETURN FALSE;
  END IF;

 END;
$$;

ALTER FUNCTION update_job_queue(INTEGER,INTEGER) OWNER TO pgbackman_user_rw;



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

   PERFORM pg_notify('channel_bs' || NEW.backup_server_id || '_pg' || NEW.pgsql_node_id,'Backup jobs for ' || pgsql_node_ || ' updated on ' || backup_server_);
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

     PERFORM pg_notify('channel_bs' || NEW.backup_server_id || '_pg' || NEW.pgsql_node_id,'Backup jobs for ' || pgsql_node_ || ' updated on ' || backup_server_);
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

     PERFORM pg_notify('channel_bs' || NEW.backup_server_id || '_pg' || NEW.pgsql_node_id,'Backup jobs for ' || pgsql_node_ || ' updated on ' || backup_server_);
    END IF;  

    SELECT count(*) FROM job_queue WHERE backup_server_id = OLD.backup_server_id AND pgsql_node_id = NEW.pgsql_node_id AND is_assigned IS FALSE INTO srv_cnt;
    SELECT hostname || '.' || domain_name FROM backup_server WHERE server_id = OLD.backup_server_id INTO backup_server_; 
    SELECT hostname || '.' || domain_name FROM pgsql_node WHERE node_id = NEW.pgsql_node_id INTO pgsql_node_; 

    IF srv_cnt = 0 THEN
     EXECUTE 'INSERT INTO job_queue (backup_server_id,pgsql_node_id) VALUES ($1,$2)'
     USING OLD.backup_server_id,
           NEW.pgsql_node_id;

     PERFORM pg_notify('channel_bs' || OLD.backup_server_id || '_pg' || NEW.pgsql_node_id,'Backup jobs for ' || pgsql_node_ || ' updated on ' || backup_server_);
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

   PERFORM pg_notify('channel_bs' || OLD.backup_server_id || '_pg' || OLD.pgsql_node_id,'Backup jobs for ' || pgsql_node_ || ' updated on ' || backup_server_);
  END IF;         

 END IF;

 RETURN NULL;
END;
$$;

ALTER FUNCTION update_job_queue() OWNER TO pgbackman_user_rw;

CREATE TRIGGER update_job_queue AFTER INSERT OR UPDATE OR DELETE
    ON backup_job_definition FOR EACH ROW 
    EXECUTE PROCEDURE update_job_queue();


-- ------------------------------------------------------------
-- Function: get_next_crontab_id_to_generate()
--
-- ------------------------------------------------------------

CREATE OR REPLACE FUNCTION get_next_crontab_id_to_generate(INTEGER) RETURNS INTEGER
 LANGUAGE plpgsql 
 SECURITY INVOKER 
 SET search_path = public, pg_temp
 AS $$
 DECLARE
  backup_server_id_ ALIAS FOR $1;
  pgsql_node_id INTEGER;
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
        || ' FROM job_queue'
        || ' WHERE backup_server_id = $1'
        || ' AND is_assigned IS FALSE'
        || ' LIMIT 1'
        || ' FOR UPDATE NOWAIT'
      INTO assigned_id
      USING backup_server_id_;
      EXIT;
    EXCEPTION
      WHEN lock_not_available THEN
        -- do nothing. loop again and hope we get a lock
    END;

    PERFORM pg_sleep(random());

  END LOOP;

  EXECUTE 'DELETE FROM job_queue'
    || ' WHERE id = $1'
    || ' RETURNING pgsql_node_id'
  USING assigned_id
  INTO pgsql_node_id;

  RETURN pgsql_node_id;

 END;
$$;

ALTER FUNCTION get_next_crontab_id_to_generate(INTEGER) OWNER TO pgbackman_user_rw;

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

  v_msg     TEXT;
  v_detail  TEXT;
  v_context TEXT;
 BEGIN

   IF hostname_ = '' OR hostname_ IS NULL THEN
      RAISE EXCEPTION 'Hostname value has not been defined';
   END IF;

   IF domain_name_ = '' OR domain_name_ IS NULL THEN
    domain_name_ := get_default_backup_server_parameter('domain');
   END IF;

   IF status_ = '' OR status_ IS NULL THEN
    status_ := get_default_backup_server_parameter('backup_server_status');
   END IF;

   EXECUTE 'INSERT INTO backup_server (hostname,domain_name,status,remarks) VALUES ($1,$2,$3,$4)'
   USING hostname_,
         domain_name_,
         status_,
         remarks_;         

   RETURN TRUE;
 EXCEPTION WHEN others THEN
   	GET STACKED DIAGNOSTICS	
            v_msg     = MESSAGE_TEXT,
            v_detail  = PG_EXCEPTION_DETAIL,
            v_context = PG_EXCEPTION_CONTEXT;
        RAISE EXCEPTION E'\n----------------------------------------------\nEXCEPTION:\n----------------------------------------------\nMESSAGE: % \nDETAIL : % \nCONTEXT: % \n----------------------------------------------', v_msg, v_detail, v_context;
  
END;
$$;

ALTER FUNCTION register_backup_server(TEXT,TEXT,CHARACTER VARYING,TEXT) OWNER TO pgbackman_user_rw;


-- ------------------------------------------------------------
-- Function: delete_backup_server()
--
-- ------------------------------------------------------------

CREATE OR REPLACE FUNCTION delete_backup_server(INTEGER) RETURNS BOOLEAN
 LANGUAGE plpgsql 
 SECURITY INVOKER 
 SET search_path = public, pg_temp
 AS $$
 DECLARE
  backup_server_id_ ALIAS FOR $1;
  server_cnt INTEGER;

  v_msg     TEXT;
  v_detail  TEXT;
  v_context TEXT;
 BEGIN

	SELECT count(*) FROM backup_server WHERE server_id = backup_server_id_ INTO server_cnt;

   IF server_cnt != 0 THEN

     EXECUTE 'DELETE FROM backup_server_config WHERE server_id = $1'
     USING backup_server_id_;
   
     EXECUTE 'DELETE FROM backup_server WHERE server_id = $1'
     USING backup_server_id_;

     RETURN TRUE;
    ELSE
      RAISE EXCEPTION 'Backup server % does not exist',backup_server_id_; 
    END IF;
	   
   EXCEPTION WHEN others THEN
   	GET STACKED DIAGNOSTICS	
            v_msg     = MESSAGE_TEXT,
            v_detail  = PG_EXCEPTION_DETAIL,
            v_context = PG_EXCEPTION_CONTEXT;
        RAISE EXCEPTION E'\n----------------------------------------------\nEXCEPTION:\n----------------------------------------------\nMESSAGE: % \nDETAIL : % \nCONTEXT: % \n----------------------------------------------\n', v_msg, v_detail, v_context;
  END;
$$;

ALTER FUNCTION delete_backup_server(TEXT) OWNER TO pgbackman_user_rw;



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

  v_msg     TEXT;
  v_detail  TEXT;
  v_context TEXT;
 BEGIN

   IF hostname_ = '' OR hostname_ IS NULL THEN
      RAISE EXCEPTION 'Hostname value has not been defined';
   END IF;

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

    EXECUTE 'INSERT INTO pgsql_node (hostname,domain_name,pgport,admin_user,status,remarks) VALUES ($1,$2,$3,$4,$5,$6)'
    USING hostname_,
          domain_name_,
          pgport_,
          admin_user_,
          status_,
          remarks_;         

    RETURN TRUE;
 EXCEPTION WHEN others THEN
   	GET STACKED DIAGNOSTICS	
            v_msg     = MESSAGE_TEXT,
            v_detail  = PG_EXCEPTION_DETAIL,
            v_context = PG_EXCEPTION_CONTEXT;
        RAISE EXCEPTION E'\n----------------------------------------------\nEXCEPTION:\n----------------------------------------------\nMESSAGE: % \nDETAIL : % \nCONTEXT: % \n----------------------------------------------\n', v_msg, v_detail, v_context;
  
END;
$$;

ALTER FUNCTION register_pgsql_node(TEXT,TEXT,INTEGER,TEXT,CHARACTER VARYING,TEXT) OWNER TO pgbackman_user_rw;


-- ------------------------------------------------------------
-- Function: delete_pgsql_node()
--
-- ------------------------------------------------------------

CREATE OR REPLACE FUNCTION delete_pgsql_node(INTEGER) RETURNS BOOLEAN
 LANGUAGE plpgsql 
 SECURITY INVOKER 
 SET search_path = public, pg_temp
 AS $$
 DECLARE
  pgsql_node_id_ ALIAS FOR $1;
  node_cnt INTEGER;

  v_msg     TEXT;
  v_detail  TEXT;
  v_context TEXT;
 BEGIN

 SELECT count(*) FROM pgsql_node WHERE node_id = pgsql_node_id_ INTO node_cnt;

   IF node_cnt !=0 THEN    
    
    EXECUTE 'DELETE FROM pgsql_node_config WHERE node_id = $1'
    USING pgsql_node_id_;

    EXECUTE 'DELETE FROM job_queue WHERE pgsql_node_id = $1'
    USING pgsql_node_id_;

    EXECUTE 'DELETE FROM pgsql_node WHERE node_id = $1'
    USING pgsql_node_id_;

    RETURN TRUE;
   ELSE
    RAISE EXCEPTION 'PgSQL node % does not exist',pgsql_node_id_;
   END IF; 

  EXCEPTION WHEN others THEN
   	GET STACKED DIAGNOSTICS	
            v_msg     = MESSAGE_TEXT,
            v_detail  = PG_EXCEPTION_DETAIL,
            v_context = PG_EXCEPTION_CONTEXT;
        RAISE EXCEPTION E'\n----------------------------------------------\nEXCEPTION:\n----------------------------------------------\nMESSAGE: % \nDETAIL : % \nCONTEXT: % \n----------------------------------------------\n', v_msg, v_detail, v_context;

END;
$$;

ALTER FUNCTION delete_pgsql_node(TEXT) OWNER TO pgbackman_user_rw;



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

  v_msg     TEXT;
  v_detail  TEXT;
  v_context TEXT;
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

   SELECT get_backup_server_id(backup_server_) INTO backup_server_id_;
   SELECT get_pgsql_node_id(pgsql_node_) INTO pgsql_node_id_;

   IF backup_server_id_ IS NULL THEN
     RAISE EXCEPTION 'Backup server % does not exist',backup_server_ ;
   ELSIF pgsql_node_id_ IS NULL THEN
     RAISE EXCEPTION 'PgSQL node % does not exist',pgsql_node_ ;
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
 EXCEPTION WHEN others THEN
   	GET STACKED DIAGNOSTICS	
            v_msg     = MESSAGE_TEXT,
            v_detail  = PG_EXCEPTION_DETAIL,
            v_context = PG_EXCEPTION_CONTEXT;
        RAISE EXCEPTION E'\n----------------------------------------------\nEXCEPTION:\n----------------------------------------------\nMESSAGE: % \nDETAIL : % \nCONTEXT: % \n----------------------------------------------\n', v_msg, v_detail, v_context;

END;
$$;

ALTER FUNCTION register_backup_job(TEXT,TEXT,TEXT,CHARACTER VARYING,CHARACTER VARYING,CHARACTER VARYING,CHARACTER VARYING,CHARACTER VARYING,CHARACTER VARYING,BOOLEAN,INTERVAL,INTEGER,TEXT,CHARACTER VARYING,TEXT) OWNER TO pgbackman_user_rw;


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
-- Function: get_backup_server_parameter()
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

 v_msg     TEXT;
 v_detail  TEXT;
 v_context TEXT; 
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

   EXCEPTION WHEN others THEN
   	GET STACKED DIAGNOSTICS	
            v_msg     = MESSAGE_TEXT,
            v_detail  = PG_EXCEPTION_DETAIL,
            v_context = PG_EXCEPTION_CONTEXT;
        RAISE EXCEPTION E'\n----------------------------------------------\nEXCEPTION:\n----------------------------------------------\nMESSAGE: % \nDETAIL : % \nCONTEXT: % \n----------------------------------------------\n', v_msg, v_detail, v_context;


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

 v_msg     TEXT;
 v_detail  TEXT;
 v_context TEXT;
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

    EXCEPTION WHEN others THEN
   	GET STACKED DIAGNOSTICS	
            v_msg     = MESSAGE_TEXT,
            v_detail  = PG_EXCEPTION_DETAIL,
            v_context = PG_EXCEPTION_CONTEXT;
        RAISE EXCEPTION E'\n----------------------------------------------\nEXCEPTION:\n----------------------------------------------\nMESSAGE: % \nDETAIL : % \nCONTEXT: % \n----------------------------------------------\n', v_msg, v_detail, v_context;

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
 backup_server_ TEXT := '';

 BEGIN
  --
  -- This function returns the fqdn of a backup server
  --

  SELECT hostname || '.' || domain_name from backup_server WHERE server_id = parameter_ INTO backup_server_;

  IF backup_server_ IS NULL OR backup_server_ = '' THEN
    RAISE EXCEPTION 'Backup server with ID: % does not exist in this system',parameter_;
  END IF;

  RETURN backup_server_;
 END;
$$;

ALTER FUNCTION get_backup_server_fqdn(INTEGER) OWNER TO pgbackman_user_rw;


-- ------------------------------------------------------------
-- Function: get_backup_server_id()
--
-- ------------------------------------------------------------

CREATE OR REPLACE FUNCTION get_backup_server_id(TEXT) RETURNS INTEGER 
 LANGUAGE plpgsql 
 SECURITY INVOKER 
 SET search_path = public, pg_temp
 AS $$
 DECLARE
  backup_server_fqdn ALIAS FOR $1; 
  backup_server_id_ TEXT := '';
 BEGIN
  --
  -- This function returns the server_id of a backup server
  --

  SELECT server_id FROM backup_server WHERE hostname || '.' || domain_name = backup_server_fqdn INTO backup_server_id_;

  IF backup_server_id_ IS NULL OR backup_server_id_ = '' THEN
    RAISE EXCEPTION 'Backup server with FQDN: % does not exist in this system',backup_server_fqdn;
  END IF;

  RETURN backup_server_id_;
 END;
$$;

ALTER FUNCTION get_backup_server_id(TEXT) OWNER TO pgbackman_user_rw;


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
 pgsql_node_ TEXT := '';

 BEGIN
  --
  -- This function returns the fqdn of a pgsql node
  --

  SELECT hostname || '.' || domain_name from pgsql_node WHERE node_id = parameter_ INTO pgsql_node_;

  IF pgsql_node_ IS NULL OR pgsql_node_ = '' THEN
    RAISE EXCEPTION 'PgSQL node with ID: % does not exist in this system',parameter_;
  END IF;

  RETURN pgsql_node_;
 END;
$$;

ALTER FUNCTION get_pgsql_node_fqdn(INTEGER) OWNER TO pgbackman_user_rw;


-- ------------------------------------------------------------
-- Function: get_pgsql_node_id()
--
-- ------------------------------------------------------------

CREATE OR REPLACE FUNCTION get_pgsql_node_id(TEXT) RETURNS INTEGER 
 LANGUAGE plpgsql 
 SECURITY INVOKER 
 SET search_path = public, pg_temp
 AS $$
 DECLARE
 pgsql_node_fqdn ALIAS FOR $1; 
 pgsql_node_id_ TEXT := '';

 BEGIN
  --
  -- This function returns the server_id of a backup server
  --

  SELECT node_id FROM pgsql_node WHERE hostname || '.' || domain_name = pgsql_node_fqdn INTO pgsql_node_id_;

  IF pgsql_node_id_ IS NULL OR pgsql_node_id_ = '' THEN
    RAISE EXCEPTION 'PgSQL node with FQDN: % does not exist in this system',pgsql_node_fqdn;
  END IF;

  RETURN pgsql_node_id_;
 END;
$$;

ALTER FUNCTION get_pgsql_node_id(TEXT) OWNER TO pgbackman_user_rw;


-- ------------------------------------------------------------
-- Function: get_listen_channel_names()
--
-- ------------------------------------------------------------

CREATE OR REPLACE FUNCTION get_listen_channel_names(INTEGER) RETURNS SETOF TEXT 
 LANGUAGE sql
 SECURITY INVOKER 
 SET search_path = public, pg_temp
 AS $$
  SELECT 'channel_pgsql_nodes_updated' AS channel
  UNION
  SELECT 'channel_bs' || $1 || '_pg' || node_id AS channel FROM pgsql_node ORDER BY channel DESC
$$;

ALTER FUNCTION get_listen_channel_names(INTEGER) OWNER TO pgbackman_user_rw;


-- ------------------------------------------------------------
-- Function: generate_crontab_file()
--
-- ------------------------------------------------------------

CREATE OR REPLACE FUNCTION generate_crontab_backup_jobs(INTEGER,INTEGER) RETURNS TEXT 
 LANGUAGE plpgsql
 SECURITY INVOKER 
 SET search_path = public, pg_temp
 AS $$
 DECLARE
  backup_server_id_ ALIAS FOR $1;
  pgsql_node_id_ ALIAS FOR $2;
  backup_server_fqdn TEXT;
  pgsql_node_fqdn TEXT;
  pgsql_node_port TEXT;
  job_row RECORD;

  logs_email TEXT := '';
  pg_node_cron_file TEXT := '';
  admin_user TEXT := '';
  pgbackman_dump TEXT := '';

  output TEXT := '';
BEGIN

 logs_email := get_pgsql_node_parameter(pgsql_node_id_,'logs_email');
 pg_node_cron_file := get_pgsql_node_parameter(pgsql_node_id_,'pg_node_cron_file');
 backup_server_fqdn := get_backup_server_fqdn(backup_server_id_);
 pgsql_node_fqdn := get_pgsql_node_fqdn(pgsql_node_id_);
 pgsql_node_port := get_pgsql_node_port(pgsql_node_id_);
 admin_user := get_pgsql_node_admin_user(pgsql_node_id_);
 pgbackman_dump := get_backup_server_parameter(backup_server_id_,'pgbackman_dump');

 output := output || '# File: ' || COALESCE(pg_node_cron_file,'') || E'\n';
 output := output || '# ' || E'\n';
 output := output || '# This crontab file is generated automatically' || E'\n';
 output := output || '# and contains the backup jobs to be run' || E'\n';
 output := output || '# for the PgSQL node ' || COALESCE(pgsql_node_fqdn,'') || E'\n';
 output := output || '# in the backup server ' || COALESCE(backup_server_fqdn,'') || E'\n';
 output := output || '# ' || E'\n';
 output := output || '# Generated: ' || now() || E'\n';
 output := output || '#' || E'\n';

 output := output || 'SHELL=/bin/bash' || E'\n';
 output := output || 'PATH=/sbin:/bin:/usr/sbin:/usr/bin' || E'\n';
 output := output || 'MAILTO=' || COALESCE(logs_email,'') || E'\n';
 output := output || E'\n';     

 --
 -- Generating backup jobs output for jobs
 -- with job_status = ACTIVE for a backup server
 -- and a PgSQL node 
 --

 FOR job_row IN (
 SELECT *
 FROM backup_job_definition
 WHERE backup_server_id = backup_server_id_
 AND pgsql_node_id = pgsql_node_id_
 AND job_status IN ('ACTIVE')
 ORDER BY dbname,month_cron,weekday_cron,hours_cron,minutes_cron,backup_code
 ) LOOP

  output := output || COALESCE(job_row.minutes_cron, '*') || ' ' || COALESCE(job_row.hours_cron, '*') || ' ' || COALESCE(job_row.day_month_cron, '*') || ' ' || COALESCE(job_row.month_cron, '*') || ' ' || COALESCE(job_row.weekday_cron, '*');

  output := output || ' ' || admin_user;
  output := output || ' ' || pgbackman_dump || 
  	    	   ' -H ' || pgsql_node_fqdn ||
		   ' -p ' || pgsql_node_port ||
		   ' -U ' || admin_user || 
		   ' -j ' || job_row.def_id || 
		   ' -d ' || job_row.dbname || 
		   ' -e ' || job_row.encryption::TEXT || 
		   ' -c ' || job_row.backup_code;

  IF job_row.extra_parameters != '' AND job_row.extra_parameters IS NOT NULL THEN
    output := output || ' -P ' || job_row.extra_parameters;
  END IF;
 
  output := output || E'\n';

 END LOOP;

 RETURN output;
END;
$$;

ALTER FUNCTION generate_crontab_backup_jobs(INTEGER,INTEGER) OWNER TO pgbackman_user_rw;


-- ------------------------------------------------------------
-- Function: get_pgsql_node_dsn()
--
-- ------------------------------------------------------------

CREATE OR REPLACE FUNCTION get_pgsql_node_dsn(INTEGER) RETURNS TEXT 
 LANGUAGE plpgsql 
 SECURITY INVOKER 
 SET search_path = public, pg_temp
 AS $$
 DECLARE
 node_id_ ALIAS FOR $1;
 value_ TEXT := '';

 BEGIN
  --
  -- This function returns the DSN value for a pgsql_node
  --

  SELECT 'host=' || hostname || '.' || domain_name || ' port=' || pgport || ' dbname=' || admin_user || ' user=' || admin_user FROM pgsql_node WHERE node_id = node_id_ INTO value_;
  RETURN value_;
 END;
$$;

ALTER FUNCTION get_pgsql_node_dsn(INTEGER) OWNER TO pgbackman_user_rw;


-- ------------------------------------------------------------
-- Function: get_pgsql_node_port()
--
-- ------------------------------------------------------------

CREATE OR REPLACE FUNCTION get_pgsql_node_port(INTEGER) RETURNS TEXT 
 LANGUAGE plpgsql 
 SECURITY INVOKER 
 SET search_path = public, pg_temp
 AS $$
 DECLARE
 node_id_ ALIAS FOR $1;
 value_ TEXT := '';

 BEGIN
  --
  -- This function returns the DSN value for a pgsql_node
  --

  SELECT pgport FROM pgsql_node WHERE node_id = node_id_ INTO value_;
  RETURN value_;
 END;
$$;

ALTER FUNCTION get_pgsql_node_port(INTEGER) OWNER TO pgbackman_user_rw;


-- ------------------------------------------------------------
-- Function: get_pgsql_node_admin_user()
--
-- ------------------------------------------------------------

CREATE OR REPLACE FUNCTION get_pgsql_node_admin_user(INTEGER) RETURNS TEXT 
 LANGUAGE plpgsql 
 SECURITY INVOKER 
 SET search_path = public, pg_temp
 AS $$
 DECLARE
 node_id_ ALIAS FOR $1;
 value_ TEXT := '';

 BEGIN
  --
  -- This function returns the DSN value for a pgsql_node
  --

  SELECT admin_user FROM pgsql_node WHERE node_id = node_id_ INTO value_;
  RETURN value_;
 END;
$$;

ALTER FUNCTION get_pgsql_node_admin_user(INTEGER) OWNER TO pgbackman_user_rw;


-- ------------------------------------------------------------
-- Function: register_backup_job_catalog()
--
-- ------------------------------------------------------------

CREATE OR REPLACE FUNCTION register_backup_job_catalog(INTEGER,INTEGER,INTEGER,TEXT,TIMESTAMP WITH TIME ZONE,TIMESTAMP WITH TIME ZONE,INTERVAL,TEXT,BIGINT,TEXT,TEXT,BIGINT,TEXT,TEXT,BIGINT,TEXT,TEXT,TEXT) RETURNS BOOLEAN
 LANGUAGE plpgsql 
 SECURITY INVOKER 
 SET search_path = public, pg_temp
 AS $$
 DECLARE

  def_id_ ALIAS FOR $1;
  backup_server_id_ ALIAS FOR $2;
  pgsql_node_id_ ALIAS FOR $3;
  dbname_ ALIAS FOR $4;
  started_ ALIAS FOR $5;
  finished_ ALIAS FOR $6;
  duration_ ALIAS FOR $7;
  pg_dump_file_ ALIAS FOR $8;
  pg_dump_file_size_ ALIAS FOR $9;
  pg_dump_log_file_ ALIAS FOR $10;
  pg_dump_roles_file_ ALIAS FOR $11;
  pg_dump_roles_file_size_ ALIAS FOR $12;
  pg_dump_roles_log_file_ ALIAS FOR $13;
  pg_dump_dbconfig_file_ ALIAS FOR $14;
  pg_dump_dbconfig_file_size_ ALIAS FOR $15;
  pg_dump_dbconfig_log_file_ ALIAS FOR $16;
  global_log_file_ ALIAS FOR $17;
  execution_status_ ALIAS FOR $18;

  v_msg     TEXT;
  v_detail  TEXT;
  v_context TEXT; 

 BEGIN
    EXECUTE 'INSERT INTO backup_job_catalog (def_id,
					     backup_server_id,
					     pgsql_node_id,
					     dbname,
					     started,
					     finished,
					     duration,
					     pg_dump_file,
					     pg_dump_file_size,
					     pg_dump_log_file,
					     pg_dump_roles_file,
					     pg_dump_roles_file_size,
					     pg_dump_roles_log_file,
					     pg_dump_dbconfig_file,
					     pg_dump_dbconfig_file_size,
					     pg_dump_dbconfig_log_file,
					     global_log_file,
					     execution_status) 
	     VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18)'
    USING  def_id_,
    	   backup_server_id_,
  	   pgsql_node_id_,
  	   dbname_,
  	   started_,
  	   finished_,
  	   duration_,
  	   pg_dump_file_,
  	   pg_dump_file_size_,
	   pg_dump_log_file_,
  	   pg_dump_roles_file_,
  	   pg_dump_roles_file_size_,
  	   pg_dump_roles_log_file_,
  	   pg_dump_dbconfig_file_,
  	   pg_dump_dbconfig_file_size_,
  	   pg_dump_dbconfig_log_file_,
  	   global_log_file_,
  	   execution_status_;

   RETURN TRUE;
 EXCEPTION WHEN others THEN
   	GET STACKED DIAGNOSTICS	
            v_msg     = MESSAGE_TEXT,
            v_detail  = PG_EXCEPTION_DETAIL,
            v_context = PG_EXCEPTION_CONTEXT;
        RAISE EXCEPTION E'\n----------------------------------------------\nEXCEPTION:\n----------------------------------------------\nMESSAGE: % \nDETAIL : % \nCONTEXT: % \n----------------------------------------------\n', v_msg, v_detail, v_context;
  

 END;
$$;

ALTER FUNCTION register_backup_job_catalog(INTEGER,INTEGER,INTEGER,TEXT,TIMESTAMP WITH TIME ZONE,TIMESTAMP WITH TIME ZONE,INTERVAL,TEXT,BIGINT,TEXT,TEXT,BIGINT,TEXT,TEXT,BIGINT,TEXT,TEXT,TEXT) OWNER TO pgbackman_user_rw;



-- ------------------------------------------------------------
-- Views
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


CREATE OR REPLACE VIEW show_pgsql_nodes AS
SELECT lpad(node_id::text,6,'0') AS "NodeID", 
       hostname || '.' || domain_name AS "FQDN",
       pgport AS "Pgport",
       admin_user AS "Admin user",
       status AS "Status",
       remarks AS "Remarks" 
       FROM pgsql_node
       ORDER BY domain_name,hostname,"Pgport","Admin user","Status";

CREATE OR REPLACE VIEW show_backup_servers AS
SELECT lpad(server_id::text,5,'0') AS "SrvID", 
       hostname || '.' || domain_name AS "FQDN",
       status AS "Status",
       remarks AS "Remarks" 
       FROM backup_server
       ORDER BY domain_name,hostname,"Status";

CREATE OR REPLACE VIEW show_backup_definitions AS
SELECT lpad(def_id::text,8,'0') AS "DefID",
       backup_server_id,
       get_backup_server_fqdn(backup_server_id) AS "Backup server",
       pgsql_node_id,
       get_pgsql_node_fqdn(pgsql_node_id) AS "PgSQL node",
       dbname AS "DBname",
       minutes_cron || ' ' || hours_cron || ' ' || weekday_cron || ' ' || month_cron || ' ' || day_month_cron AS "Schedule",
       backup_code AS "Code",
       encryption::TEXT AS "Encryption",
       retention_period::TEXT || ' (' || retention_redundancy::TEXT || ')' AS "Retention",
       job_status AS "Status",
       extra_parameters AS "Parameters"
FROM backup_job_definition
ORDER BY backup_server_id,pgsql_node_id,"DBname","Code","Status";

CREATE OR REPLACE VIEW show_backup_catalog AS
   SELECT lpad(a.bck_id::text,12,'0') AS "BckID",
       date_trunc('seconds',a.finished) AS "Finished",
       a.backup_server_id,
       get_backup_server_fqdn(a.backup_server_id) AS "Backup server",
       a.pgsql_node_id,
       get_pgsql_node_fqdn(a.pgsql_node_id) AS "PgSQL node",
       a.dbname AS "DBname",
       date_trunc('seconds',a.duration) AS "Duration",
       pg_size_pretty(a.pg_dump_file_size+a.pg_dump_roles_file_size+a.pg_dump_dbconfig_file_size) AS "Size",
       b.backup_code AS "Code",
       a.execution_status AS "Status" 
   FROM backup_job_catalog a 
   JOIN backup_job_definition b ON a.def_id = b.def_id 
   ORDER BY "Finished" DESC,backup_server_id,pgsql_node_id,"DBname","Code","Status";

CREATE OR REPLACE VIEW show_backup_job_details AS
   SELECT lpad(a.bck_id::text,12,'0') AS "BckID",
       a.bck_id AS bck_id,
       date_trunc('seconds',a.registered) AS "Registered",
       date_trunc('seconds',a.started) AS "Started",
       date_trunc('seconds',a.finished) AS "Finished",
       date_trunc('seconds',a.finished+b.retention_period) AS "Valid until",
       date_trunc('seconds',a.duration) AS "Duration",
       lpad(a.def_id::text,8,'0') AS "DefID",
       b.retention_period::TEXT || ' (' || b.retention_redundancy::TEXT || ')' AS "Retention",
       b.minutes_cron || ' ' || b.hours_cron || ' ' || b.weekday_cron || ' ' || b.month_cron || ' ' || b.day_month_cron AS "Schedule",
       b.encryption::TEXT AS "Encryption",
       b.extra_parameters As "Extra parameters",
       a.backup_server_id,
       get_backup_server_fqdn(a.backup_server_id) AS "Backup server",
       a.pgsql_node_id,
       get_pgsql_node_fqdn(a.pgsql_node_id) AS "PgSQL node",
       a.dbname AS "DBname",
       a.pg_dump_file AS "DB dump file",
       a.pg_dump_log_file AS "DB log file",
       pg_size_pretty(a.pg_dump_file_size) AS "DB dump size",
       a.pg_dump_roles_file AS "DB roles dump file",
       a.pg_dump_roles_log_file AS "DB roles log file",
       pg_size_pretty(a.pg_dump_roles_file_size) AS "DB roles dump size",
       a.pg_dump_dbconfig_file AS "DB config dump file",
       a.pg_dump_dbconfig_log_file AS "DB config log file",
       pg_size_pretty(a.pg_dump_dbconfig_file_size) AS "DB config dump size",
       pg_size_pretty(a.pg_dump_file_size+a.pg_dump_roles_file_size+a.pg_dump_dbconfig_file_size) AS "Total size",
       b.backup_code AS "Code",
       a.execution_status AS "Status" 
   FROM backup_job_catalog a 
   JOIN backup_job_definition b ON a.def_id = b.def_id 
   ORDER BY "Finished" DESC,backup_server_id,pgsql_node_id,"DBname","Code","Status";




COMMIT;