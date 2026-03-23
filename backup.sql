--
-- PostgreSQL database dump
--

\restrict 2bU3O4z3oH5H796joTUJF74MT3udNY0XLrUXW5cOseoGFb1ztcZgkyF0Y5oc9H7

-- Dumped from database version 17.6
-- Dumped by pg_dump version 17.7 (Homebrew)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: auth; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA auth;


--
-- Name: extensions; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA extensions;


--
-- Name: graphql; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA graphql;


--
-- Name: graphql_public; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA graphql_public;


--
-- Name: pgbouncer; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA pgbouncer;


--
-- Name: public; Type: SCHEMA; Schema: -; Owner: -
--

-- *not* creating schema, since initdb creates it


--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA public IS '';


--
-- Name: realtime; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA realtime;


--
-- Name: storage; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA storage;


--
-- Name: supabase_migrations; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA supabase_migrations;


--
-- Name: vault; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA vault;


--
-- Name: pg_graphql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_graphql WITH SCHEMA graphql;


--
-- Name: EXTENSION pg_graphql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_graphql IS 'pg_graphql: GraphQL support';


--
-- Name: pg_stat_statements; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_stat_statements WITH SCHEMA extensions;


--
-- Name: EXTENSION pg_stat_statements; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_stat_statements IS 'track planning and execution statistics of all SQL statements executed';


--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: supabase_vault; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS supabase_vault WITH SCHEMA vault;


--
-- Name: EXTENSION supabase_vault; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION supabase_vault IS 'Supabase Vault Extension';


--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA extensions;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- Name: aal_level; Type: TYPE; Schema: auth; Owner: -
--

CREATE TYPE auth.aal_level AS ENUM (
    'aal1',
    'aal2',
    'aal3'
);


--
-- Name: code_challenge_method; Type: TYPE; Schema: auth; Owner: -
--

CREATE TYPE auth.code_challenge_method AS ENUM (
    's256',
    'plain'
);


--
-- Name: factor_status; Type: TYPE; Schema: auth; Owner: -
--

CREATE TYPE auth.factor_status AS ENUM (
    'unverified',
    'verified'
);


--
-- Name: factor_type; Type: TYPE; Schema: auth; Owner: -
--

CREATE TYPE auth.factor_type AS ENUM (
    'totp',
    'webauthn',
    'phone'
);


--
-- Name: oauth_authorization_status; Type: TYPE; Schema: auth; Owner: -
--

CREATE TYPE auth.oauth_authorization_status AS ENUM (
    'pending',
    'approved',
    'denied',
    'expired'
);


--
-- Name: oauth_client_type; Type: TYPE; Schema: auth; Owner: -
--

CREATE TYPE auth.oauth_client_type AS ENUM (
    'public',
    'confidential'
);


--
-- Name: oauth_registration_type; Type: TYPE; Schema: auth; Owner: -
--

CREATE TYPE auth.oauth_registration_type AS ENUM (
    'dynamic',
    'manual'
);


--
-- Name: oauth_response_type; Type: TYPE; Schema: auth; Owner: -
--

CREATE TYPE auth.oauth_response_type AS ENUM (
    'code'
);


--
-- Name: one_time_token_type; Type: TYPE; Schema: auth; Owner: -
--

CREATE TYPE auth.one_time_token_type AS ENUM (
    'confirmation_token',
    'reauthentication_token',
    'recovery_token',
    'email_change_token_new',
    'email_change_token_current',
    'phone_change_token'
);


--
-- Name: action; Type: TYPE; Schema: realtime; Owner: -
--

CREATE TYPE realtime.action AS ENUM (
    'INSERT',
    'UPDATE',
    'DELETE',
    'TRUNCATE',
    'ERROR'
);


--
-- Name: equality_op; Type: TYPE; Schema: realtime; Owner: -
--

CREATE TYPE realtime.equality_op AS ENUM (
    'eq',
    'neq',
    'lt',
    'lte',
    'gt',
    'gte',
    'in'
);


--
-- Name: user_defined_filter; Type: TYPE; Schema: realtime; Owner: -
--

CREATE TYPE realtime.user_defined_filter AS (
	column_name text,
	op realtime.equality_op,
	value text
);


--
-- Name: wal_column; Type: TYPE; Schema: realtime; Owner: -
--

CREATE TYPE realtime.wal_column AS (
	name text,
	type_name text,
	type_oid oid,
	value jsonb,
	is_pkey boolean,
	is_selectable boolean
);


--
-- Name: wal_rls; Type: TYPE; Schema: realtime; Owner: -
--

CREATE TYPE realtime.wal_rls AS (
	wal jsonb,
	is_rls_enabled boolean,
	subscription_ids uuid[],
	errors text[]
);


--
-- Name: buckettype; Type: TYPE; Schema: storage; Owner: -
--

CREATE TYPE storage.buckettype AS ENUM (
    'STANDARD',
    'ANALYTICS',
    'VECTOR'
);


--
-- Name: email(); Type: FUNCTION; Schema: auth; Owner: -
--

CREATE FUNCTION auth.email() RETURNS text
    LANGUAGE sql STABLE
    AS $$
  select 
  coalesce(
    nullif(current_setting('request.jwt.claim.email', true), ''),
    (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'email')
  )::text
$$;


--
-- Name: FUNCTION email(); Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON FUNCTION auth.email() IS 'Deprecated. Use auth.jwt() -> ''email'' instead.';


--
-- Name: jwt(); Type: FUNCTION; Schema: auth; Owner: -
--

CREATE FUNCTION auth.jwt() RETURNS jsonb
    LANGUAGE sql STABLE
    AS $$
  select 
    coalesce(
        nullif(current_setting('request.jwt.claim', true), ''),
        nullif(current_setting('request.jwt.claims', true), '')
    )::jsonb
$$;


--
-- Name: role(); Type: FUNCTION; Schema: auth; Owner: -
--

CREATE FUNCTION auth.role() RETURNS text
    LANGUAGE sql STABLE
    AS $$
  select 
  coalesce(
    nullif(current_setting('request.jwt.claim.role', true), ''),
    (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'role')
  )::text
$$;


--
-- Name: FUNCTION role(); Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON FUNCTION auth.role() IS 'Deprecated. Use auth.jwt() -> ''role'' instead.';


--
-- Name: uid(); Type: FUNCTION; Schema: auth; Owner: -
--

CREATE FUNCTION auth.uid() RETURNS uuid
    LANGUAGE sql STABLE
    AS $$
  select 
  coalesce(
    nullif(current_setting('request.jwt.claim.sub', true), ''),
    (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'sub')
  )::uuid
$$;


--
-- Name: FUNCTION uid(); Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON FUNCTION auth.uid() IS 'Deprecated. Use auth.jwt() -> ''sub'' instead.';


--
-- Name: grant_pg_cron_access(); Type: FUNCTION; Schema: extensions; Owner: -
--

CREATE FUNCTION extensions.grant_pg_cron_access() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF EXISTS (
    SELECT
    FROM pg_event_trigger_ddl_commands() AS ev
    JOIN pg_extension AS ext
    ON ev.objid = ext.oid
    WHERE ext.extname = 'pg_cron'
  )
  THEN
    grant usage on schema cron to postgres with grant option;

    alter default privileges in schema cron grant all on tables to postgres with grant option;
    alter default privileges in schema cron grant all on functions to postgres with grant option;
    alter default privileges in schema cron grant all on sequences to postgres with grant option;

    alter default privileges for user supabase_admin in schema cron grant all
        on sequences to postgres with grant option;
    alter default privileges for user supabase_admin in schema cron grant all
        on tables to postgres with grant option;
    alter default privileges for user supabase_admin in schema cron grant all
        on functions to postgres with grant option;

    grant all privileges on all tables in schema cron to postgres with grant option;
    revoke all on table cron.job from postgres;
    grant select on table cron.job to postgres with grant option;
  END IF;
END;
$$;


--
-- Name: FUNCTION grant_pg_cron_access(); Type: COMMENT; Schema: extensions; Owner: -
--

COMMENT ON FUNCTION extensions.grant_pg_cron_access() IS 'Grants access to pg_cron';


--
-- Name: grant_pg_graphql_access(); Type: FUNCTION; Schema: extensions; Owner: -
--

CREATE FUNCTION extensions.grant_pg_graphql_access() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $_$
DECLARE
    func_is_graphql_resolve bool;
BEGIN
    func_is_graphql_resolve = (
        SELECT n.proname = 'resolve'
        FROM pg_event_trigger_ddl_commands() AS ev
        LEFT JOIN pg_catalog.pg_proc AS n
        ON ev.objid = n.oid
    );

    IF func_is_graphql_resolve
    THEN
        -- Update public wrapper to pass all arguments through to the pg_graphql resolve func
        DROP FUNCTION IF EXISTS graphql_public.graphql;
        create or replace function graphql_public.graphql(
            "operationName" text default null,
            query text default null,
            variables jsonb default null,
            extensions jsonb default null
        )
            returns jsonb
            language sql
        as $$
            select graphql.resolve(
                query := query,
                variables := coalesce(variables, '{}'),
                "operationName" := "operationName",
                extensions := extensions
            );
        $$;

        -- This hook executes when `graphql.resolve` is created. That is not necessarily the last
        -- function in the extension so we need to grant permissions on existing entities AND
        -- update default permissions to any others that are created after `graphql.resolve`
        grant usage on schema graphql to postgres, anon, authenticated, service_role;
        grant select on all tables in schema graphql to postgres, anon, authenticated, service_role;
        grant execute on all functions in schema graphql to postgres, anon, authenticated, service_role;
        grant all on all sequences in schema graphql to postgres, anon, authenticated, service_role;
        alter default privileges in schema graphql grant all on tables to postgres, anon, authenticated, service_role;
        alter default privileges in schema graphql grant all on functions to postgres, anon, authenticated, service_role;
        alter default privileges in schema graphql grant all on sequences to postgres, anon, authenticated, service_role;

        -- Allow postgres role to allow granting usage on graphql and graphql_public schemas to custom roles
        grant usage on schema graphql_public to postgres with grant option;
        grant usage on schema graphql to postgres with grant option;
    END IF;

END;
$_$;


--
-- Name: FUNCTION grant_pg_graphql_access(); Type: COMMENT; Schema: extensions; Owner: -
--

COMMENT ON FUNCTION extensions.grant_pg_graphql_access() IS 'Grants access to pg_graphql';


--
-- Name: grant_pg_net_access(); Type: FUNCTION; Schema: extensions; Owner: -
--

CREATE FUNCTION extensions.grant_pg_net_access() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM pg_event_trigger_ddl_commands() AS ev
    JOIN pg_extension AS ext
    ON ev.objid = ext.oid
    WHERE ext.extname = 'pg_net'
  )
  THEN
    IF NOT EXISTS (
      SELECT 1
      FROM pg_roles
      WHERE rolname = 'supabase_functions_admin'
    )
    THEN
      CREATE USER supabase_functions_admin NOINHERIT CREATEROLE LOGIN NOREPLICATION;
    END IF;

    GRANT USAGE ON SCHEMA net TO supabase_functions_admin, postgres, anon, authenticated, service_role;

    IF EXISTS (
      SELECT FROM pg_extension
      WHERE extname = 'pg_net'
      -- all versions in use on existing projects as of 2025-02-20
      -- version 0.12.0 onwards don't need these applied
      AND extversion IN ('0.2', '0.6', '0.7', '0.7.1', '0.8', '0.10.0', '0.11.0')
    ) THEN
      ALTER function net.http_get(url text, params jsonb, headers jsonb, timeout_milliseconds integer) SECURITY DEFINER;
      ALTER function net.http_post(url text, body jsonb, params jsonb, headers jsonb, timeout_milliseconds integer) SECURITY DEFINER;

      ALTER function net.http_get(url text, params jsonb, headers jsonb, timeout_milliseconds integer) SET search_path = net;
      ALTER function net.http_post(url text, body jsonb, params jsonb, headers jsonb, timeout_milliseconds integer) SET search_path = net;

      REVOKE ALL ON FUNCTION net.http_get(url text, params jsonb, headers jsonb, timeout_milliseconds integer) FROM PUBLIC;
      REVOKE ALL ON FUNCTION net.http_post(url text, body jsonb, params jsonb, headers jsonb, timeout_milliseconds integer) FROM PUBLIC;

      GRANT EXECUTE ON FUNCTION net.http_get(url text, params jsonb, headers jsonb, timeout_milliseconds integer) TO supabase_functions_admin, postgres, anon, authenticated, service_role;
      GRANT EXECUTE ON FUNCTION net.http_post(url text, body jsonb, params jsonb, headers jsonb, timeout_milliseconds integer) TO supabase_functions_admin, postgres, anon, authenticated, service_role;
    END IF;
  END IF;
END;
$$;


--
-- Name: FUNCTION grant_pg_net_access(); Type: COMMENT; Schema: extensions; Owner: -
--

COMMENT ON FUNCTION extensions.grant_pg_net_access() IS 'Grants access to pg_net';


--
-- Name: pgrst_ddl_watch(); Type: FUNCTION; Schema: extensions; Owner: -
--

CREATE FUNCTION extensions.pgrst_ddl_watch() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  cmd record;
BEGIN
  FOR cmd IN SELECT * FROM pg_event_trigger_ddl_commands()
  LOOP
    IF cmd.command_tag IN (
      'CREATE SCHEMA', 'ALTER SCHEMA'
    , 'CREATE TABLE', 'CREATE TABLE AS', 'SELECT INTO', 'ALTER TABLE'
    , 'CREATE FOREIGN TABLE', 'ALTER FOREIGN TABLE'
    , 'CREATE VIEW', 'ALTER VIEW'
    , 'CREATE MATERIALIZED VIEW', 'ALTER MATERIALIZED VIEW'
    , 'CREATE FUNCTION', 'ALTER FUNCTION'
    , 'CREATE TRIGGER'
    , 'CREATE TYPE', 'ALTER TYPE'
    , 'CREATE RULE'
    , 'COMMENT'
    )
    -- don't notify in case of CREATE TEMP table or other objects created on pg_temp
    AND cmd.schema_name is distinct from 'pg_temp'
    THEN
      NOTIFY pgrst, 'reload schema';
    END IF;
  END LOOP;
END; $$;


--
-- Name: pgrst_drop_watch(); Type: FUNCTION; Schema: extensions; Owner: -
--

CREATE FUNCTION extensions.pgrst_drop_watch() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
  obj record;
BEGIN
  FOR obj IN SELECT * FROM pg_event_trigger_dropped_objects()
  LOOP
    IF obj.object_type IN (
      'schema'
    , 'table'
    , 'foreign table'
    , 'view'
    , 'materialized view'
    , 'function'
    , 'trigger'
    , 'type'
    , 'rule'
    )
    AND obj.is_temporary IS false -- no pg_temp objects
    THEN
      NOTIFY pgrst, 'reload schema';
    END IF;
  END LOOP;
END; $$;


--
-- Name: set_graphql_placeholder(); Type: FUNCTION; Schema: extensions; Owner: -
--

CREATE FUNCTION extensions.set_graphql_placeholder() RETURNS event_trigger
    LANGUAGE plpgsql
    AS $_$
    DECLARE
    graphql_is_dropped bool;
    BEGIN
    graphql_is_dropped = (
        SELECT ev.schema_name = 'graphql_public'
        FROM pg_event_trigger_dropped_objects() AS ev
        WHERE ev.schema_name = 'graphql_public'
    );

    IF graphql_is_dropped
    THEN
        create or replace function graphql_public.graphql(
            "operationName" text default null,
            query text default null,
            variables jsonb default null,
            extensions jsonb default null
        )
            returns jsonb
            language plpgsql
        as $$
            DECLARE
                server_version float;
            BEGIN
                server_version = (SELECT (SPLIT_PART((select version()), ' ', 2))::float);

                IF server_version >= 14 THEN
                    RETURN jsonb_build_object(
                        'errors', jsonb_build_array(
                            jsonb_build_object(
                                'message', 'pg_graphql extension is not enabled.'
                            )
                        )
                    );
                ELSE
                    RETURN jsonb_build_object(
                        'errors', jsonb_build_array(
                            jsonb_build_object(
                                'message', 'pg_graphql is only available on projects running Postgres 14 onwards.'
                            )
                        )
                    );
                END IF;
            END;
        $$;
    END IF;

    END;
$_$;


--
-- Name: FUNCTION set_graphql_placeholder(); Type: COMMENT; Schema: extensions; Owner: -
--

COMMENT ON FUNCTION extensions.set_graphql_placeholder() IS 'Reintroduces placeholder function for graphql_public.graphql';


--
-- Name: get_auth(text); Type: FUNCTION; Schema: pgbouncer; Owner: -
--

CREATE FUNCTION pgbouncer.get_auth(p_usename text) RETURNS TABLE(username text, password text)
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO ''
    AS $_$
  BEGIN
      RAISE DEBUG 'PgBouncer auth request: %', p_usename;

      RETURN QUERY
      SELECT
          rolname::text,
          CASE WHEN rolvaliduntil < now()
              THEN null
              ELSE rolpassword::text
          END
      FROM pg_authid
      WHERE rolname=$1 and rolcanlogin;
  END;
  $_$;


--
-- Name: set_updated_at(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.set_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
  new.updated_at = now();
  return new;
end;
$$;


--
-- Name: apply_rls(jsonb, integer); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.apply_rls(wal jsonb, max_record_bytes integer DEFAULT (1024 * 1024)) RETURNS SETOF realtime.wal_rls
    LANGUAGE plpgsql
    AS $$
declare
-- Regclass of the table e.g. public.notes
entity_ regclass = (quote_ident(wal ->> 'schema') || '.' || quote_ident(wal ->> 'table'))::regclass;

-- I, U, D, T: insert, update ...
action realtime.action = (
    case wal ->> 'action'
        when 'I' then 'INSERT'
        when 'U' then 'UPDATE'
        when 'D' then 'DELETE'
        else 'ERROR'
    end
);

-- Is row level security enabled for the table
is_rls_enabled bool = relrowsecurity from pg_class where oid = entity_;

subscriptions realtime.subscription[] = array_agg(subs)
    from
        realtime.subscription subs
    where
        subs.entity = entity_
        -- Filter by action early - only get subscriptions interested in this action
        -- action_filter column can be: '*' (all), 'INSERT', 'UPDATE', or 'DELETE'
        and (subs.action_filter = '*' or subs.action_filter = action::text);

-- Subscription vars
roles regrole[] = array_agg(distinct us.claims_role::text)
    from
        unnest(subscriptions) us;

working_role regrole;
claimed_role regrole;
claims jsonb;

subscription_id uuid;
subscription_has_access bool;
visible_to_subscription_ids uuid[] = '{}';

-- structured info for wal's columns
columns realtime.wal_column[];
-- previous identity values for update/delete
old_columns realtime.wal_column[];

error_record_exceeds_max_size boolean = octet_length(wal::text) > max_record_bytes;

-- Primary jsonb output for record
output jsonb;

begin
perform set_config('role', null, true);

columns =
    array_agg(
        (
            x->>'name',
            x->>'type',
            x->>'typeoid',
            realtime.cast(
                (x->'value') #>> '{}',
                coalesce(
                    (x->>'typeoid')::regtype, -- null when wal2json version <= 2.4
                    (x->>'type')::regtype
                )
            ),
            (pks ->> 'name') is not null,
            true
        )::realtime.wal_column
    )
    from
        jsonb_array_elements(wal -> 'columns') x
        left join jsonb_array_elements(wal -> 'pk') pks
            on (x ->> 'name') = (pks ->> 'name');

old_columns =
    array_agg(
        (
            x->>'name',
            x->>'type',
            x->>'typeoid',
            realtime.cast(
                (x->'value') #>> '{}',
                coalesce(
                    (x->>'typeoid')::regtype, -- null when wal2json version <= 2.4
                    (x->>'type')::regtype
                )
            ),
            (pks ->> 'name') is not null,
            true
        )::realtime.wal_column
    )
    from
        jsonb_array_elements(wal -> 'identity') x
        left join jsonb_array_elements(wal -> 'pk') pks
            on (x ->> 'name') = (pks ->> 'name');

for working_role in select * from unnest(roles) loop

    -- Update `is_selectable` for columns and old_columns
    columns =
        array_agg(
            (
                c.name,
                c.type_name,
                c.type_oid,
                c.value,
                c.is_pkey,
                pg_catalog.has_column_privilege(working_role, entity_, c.name, 'SELECT')
            )::realtime.wal_column
        )
        from
            unnest(columns) c;

    old_columns =
            array_agg(
                (
                    c.name,
                    c.type_name,
                    c.type_oid,
                    c.value,
                    c.is_pkey,
                    pg_catalog.has_column_privilege(working_role, entity_, c.name, 'SELECT')
                )::realtime.wal_column
            )
            from
                unnest(old_columns) c;

    if action <> 'DELETE' and count(1) = 0 from unnest(columns) c where c.is_pkey then
        return next (
            jsonb_build_object(
                'schema', wal ->> 'schema',
                'table', wal ->> 'table',
                'type', action
            ),
            is_rls_enabled,
            -- subscriptions is already filtered by entity
            (select array_agg(s.subscription_id) from unnest(subscriptions) as s where claims_role = working_role),
            array['Error 400: Bad Request, no primary key']
        )::realtime.wal_rls;

    -- The claims role does not have SELECT permission to the primary key of entity
    elsif action <> 'DELETE' and sum(c.is_selectable::int) <> count(1) from unnest(columns) c where c.is_pkey then
        return next (
            jsonb_build_object(
                'schema', wal ->> 'schema',
                'table', wal ->> 'table',
                'type', action
            ),
            is_rls_enabled,
            (select array_agg(s.subscription_id) from unnest(subscriptions) as s where claims_role = working_role),
            array['Error 401: Unauthorized']
        )::realtime.wal_rls;

    else
        output = jsonb_build_object(
            'schema', wal ->> 'schema',
            'table', wal ->> 'table',
            'type', action,
            'commit_timestamp', to_char(
                ((wal ->> 'timestamp')::timestamptz at time zone 'utc'),
                'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"'
            ),
            'columns', (
                select
                    jsonb_agg(
                        jsonb_build_object(
                            'name', pa.attname,
                            'type', pt.typname
                        )
                        order by pa.attnum asc
                    )
                from
                    pg_attribute pa
                    join pg_type pt
                        on pa.atttypid = pt.oid
                where
                    attrelid = entity_
                    and attnum > 0
                    and pg_catalog.has_column_privilege(working_role, entity_, pa.attname, 'SELECT')
            )
        )
        -- Add "record" key for insert and update
        || case
            when action in ('INSERT', 'UPDATE') then
                jsonb_build_object(
                    'record',
                    (
                        select
                            jsonb_object_agg(
                                -- if unchanged toast, get column name and value from old record
                                coalesce((c).name, (oc).name),
                                case
                                    when (c).name is null then (oc).value
                                    else (c).value
                                end
                            )
                        from
                            unnest(columns) c
                            full outer join unnest(old_columns) oc
                                on (c).name = (oc).name
                        where
                            coalesce((c).is_selectable, (oc).is_selectable)
                            and ( not error_record_exceeds_max_size or (octet_length((c).value::text) <= 64))
                    )
                )
            else '{}'::jsonb
        end
        -- Add "old_record" key for update and delete
        || case
            when action = 'UPDATE' then
                jsonb_build_object(
                        'old_record',
                        (
                            select jsonb_object_agg((c).name, (c).value)
                            from unnest(old_columns) c
                            where
                                (c).is_selectable
                                and ( not error_record_exceeds_max_size or (octet_length((c).value::text) <= 64))
                        )
                    )
            when action = 'DELETE' then
                jsonb_build_object(
                    'old_record',
                    (
                        select jsonb_object_agg((c).name, (c).value)
                        from unnest(old_columns) c
                        where
                            (c).is_selectable
                            and ( not error_record_exceeds_max_size or (octet_length((c).value::text) <= 64))
                            and ( not is_rls_enabled or (c).is_pkey ) -- if RLS enabled, we can't secure deletes so filter to pkey
                    )
                )
            else '{}'::jsonb
        end;

        -- Create the prepared statement
        if is_rls_enabled and action <> 'DELETE' then
            if (select 1 from pg_prepared_statements where name = 'walrus_rls_stmt' limit 1) > 0 then
                deallocate walrus_rls_stmt;
            end if;
            execute realtime.build_prepared_statement_sql('walrus_rls_stmt', entity_, columns);
        end if;

        visible_to_subscription_ids = '{}';

        for subscription_id, claims in (
                select
                    subs.subscription_id,
                    subs.claims
                from
                    unnest(subscriptions) subs
                where
                    subs.entity = entity_
                    and subs.claims_role = working_role
                    and (
                        realtime.is_visible_through_filters(columns, subs.filters)
                        or (
                          action = 'DELETE'
                          and realtime.is_visible_through_filters(old_columns, subs.filters)
                        )
                    )
        ) loop

            if not is_rls_enabled or action = 'DELETE' then
                visible_to_subscription_ids = visible_to_subscription_ids || subscription_id;
            else
                -- Check if RLS allows the role to see the record
                perform
                    -- Trim leading and trailing quotes from working_role because set_config
                    -- doesn't recognize the role as valid if they are included
                    set_config('role', trim(both '"' from working_role::text), true),
                    set_config('request.jwt.claims', claims::text, true);

                execute 'execute walrus_rls_stmt' into subscription_has_access;

                if subscription_has_access then
                    visible_to_subscription_ids = visible_to_subscription_ids || subscription_id;
                end if;
            end if;
        end loop;

        perform set_config('role', null, true);

        return next (
            output,
            is_rls_enabled,
            visible_to_subscription_ids,
            case
                when error_record_exceeds_max_size then array['Error 413: Payload Too Large']
                else '{}'
            end
        )::realtime.wal_rls;

    end if;
end loop;

perform set_config('role', null, true);
end;
$$;


--
-- Name: broadcast_changes(text, text, text, text, text, record, record, text); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.broadcast_changes(topic_name text, event_name text, operation text, table_name text, table_schema text, new record, old record, level text DEFAULT 'ROW'::text) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    -- Declare a variable to hold the JSONB representation of the row
    row_data jsonb := '{}'::jsonb;
BEGIN
    IF level = 'STATEMENT' THEN
        RAISE EXCEPTION 'function can only be triggered for each row, not for each statement';
    END IF;
    -- Check the operation type and handle accordingly
    IF operation = 'INSERT' OR operation = 'UPDATE' OR operation = 'DELETE' THEN
        row_data := jsonb_build_object('old_record', OLD, 'record', NEW, 'operation', operation, 'table', table_name, 'schema', table_schema);
        PERFORM realtime.send (row_data, event_name, topic_name);
    ELSE
        RAISE EXCEPTION 'Unexpected operation type: %', operation;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Failed to process the row: %', SQLERRM;
END;

$$;


--
-- Name: build_prepared_statement_sql(text, regclass, realtime.wal_column[]); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.build_prepared_statement_sql(prepared_statement_name text, entity regclass, columns realtime.wal_column[]) RETURNS text
    LANGUAGE sql
    AS $$
      /*
      Builds a sql string that, if executed, creates a prepared statement to
      tests retrive a row from *entity* by its primary key columns.
      Example
          select realtime.build_prepared_statement_sql('public.notes', '{"id"}'::text[], '{"bigint"}'::text[])
      */
          select
      'prepare ' || prepared_statement_name || ' as
          select
              exists(
                  select
                      1
                  from
                      ' || entity || '
                  where
                      ' || string_agg(quote_ident(pkc.name) || '=' || quote_nullable(pkc.value #>> '{}') , ' and ') || '
              )'
          from
              unnest(columns) pkc
          where
              pkc.is_pkey
          group by
              entity
      $$;


--
-- Name: cast(text, regtype); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime."cast"(val text, type_ regtype) RETURNS jsonb
    LANGUAGE plpgsql IMMUTABLE
    AS $$
declare
  res jsonb;
begin
  if type_::text = 'bytea' then
    return to_jsonb(val);
  end if;
  execute format('select to_jsonb(%L::'|| type_::text || ')', val) into res;
  return res;
end
$$;


--
-- Name: check_equality_op(realtime.equality_op, regtype, text, text); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.check_equality_op(op realtime.equality_op, type_ regtype, val_1 text, val_2 text) RETURNS boolean
    LANGUAGE plpgsql IMMUTABLE
    AS $$
      /*
      Casts *val_1* and *val_2* as type *type_* and check the *op* condition for truthiness
      */
      declare
          op_symbol text = (
              case
                  when op = 'eq' then '='
                  when op = 'neq' then '!='
                  when op = 'lt' then '<'
                  when op = 'lte' then '<='
                  when op = 'gt' then '>'
                  when op = 'gte' then '>='
                  when op = 'in' then '= any'
                  else 'UNKNOWN OP'
              end
          );
          res boolean;
      begin
          execute format(
              'select %L::'|| type_::text || ' ' || op_symbol
              || ' ( %L::'
              || (
                  case
                      when op = 'in' then type_::text || '[]'
                      else type_::text end
              )
              || ')', val_1, val_2) into res;
          return res;
      end;
      $$;


--
-- Name: is_visible_through_filters(realtime.wal_column[], realtime.user_defined_filter[]); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.is_visible_through_filters(columns realtime.wal_column[], filters realtime.user_defined_filter[]) RETURNS boolean
    LANGUAGE sql IMMUTABLE
    AS $_$
    /*
    Should the record be visible (true) or filtered out (false) after *filters* are applied
    */
        select
            -- Default to allowed when no filters present
            $2 is null -- no filters. this should not happen because subscriptions has a default
            or array_length($2, 1) is null -- array length of an empty array is null
            or bool_and(
                coalesce(
                    realtime.check_equality_op(
                        op:=f.op,
                        type_:=coalesce(
                            col.type_oid::regtype, -- null when wal2json version <= 2.4
                            col.type_name::regtype
                        ),
                        -- cast jsonb to text
                        val_1:=col.value #>> '{}',
                        val_2:=f.value
                    ),
                    false -- if null, filter does not match
                )
            )
        from
            unnest(filters) f
            join unnest(columns) col
                on f.column_name = col.name;
    $_$;


--
-- Name: list_changes(name, name, integer, integer); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.list_changes(publication name, slot_name name, max_changes integer, max_record_bytes integer) RETURNS SETOF realtime.wal_rls
    LANGUAGE sql
    SET log_min_messages TO 'fatal'
    AS $$
      with pub as (
        select
          concat_ws(
            ',',
            case when bool_or(pubinsert) then 'insert' else null end,
            case when bool_or(pubupdate) then 'update' else null end,
            case when bool_or(pubdelete) then 'delete' else null end
          ) as w2j_actions,
          coalesce(
            string_agg(
              realtime.quote_wal2json(format('%I.%I', schemaname, tablename)::regclass),
              ','
            ) filter (where ppt.tablename is not null and ppt.tablename not like '% %'),
            ''
          ) w2j_add_tables
        from
          pg_publication pp
          left join pg_publication_tables ppt
            on pp.pubname = ppt.pubname
        where
          pp.pubname = publication
        group by
          pp.pubname
        limit 1
      ),
      w2j as (
        select
          x.*, pub.w2j_add_tables
        from
          pub,
          pg_logical_slot_get_changes(
            slot_name, null, max_changes,
            'include-pk', 'true',
            'include-transaction', 'false',
            'include-timestamp', 'true',
            'include-type-oids', 'true',
            'format-version', '2',
            'actions', pub.w2j_actions,
            'add-tables', pub.w2j_add_tables
          ) x
      )
      select
        xyz.wal,
        xyz.is_rls_enabled,
        xyz.subscription_ids,
        xyz.errors
      from
        w2j,
        realtime.apply_rls(
          wal := w2j.data::jsonb,
          max_record_bytes := max_record_bytes
        ) xyz(wal, is_rls_enabled, subscription_ids, errors)
      where
        w2j.w2j_add_tables <> ''
        and xyz.subscription_ids[1] is not null
    $$;


--
-- Name: quote_wal2json(regclass); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.quote_wal2json(entity regclass) RETURNS text
    LANGUAGE sql IMMUTABLE STRICT
    AS $$
      select
        (
          select string_agg('' || ch,'')
          from unnest(string_to_array(nsp.nspname::text, null)) with ordinality x(ch, idx)
          where
            not (x.idx = 1 and x.ch = '"')
            and not (
              x.idx = array_length(string_to_array(nsp.nspname::text, null), 1)
              and x.ch = '"'
            )
        )
        || '.'
        || (
          select string_agg('' || ch,'')
          from unnest(string_to_array(pc.relname::text, null)) with ordinality x(ch, idx)
          where
            not (x.idx = 1 and x.ch = '"')
            and not (
              x.idx = array_length(string_to_array(nsp.nspname::text, null), 1)
              and x.ch = '"'
            )
          )
      from
        pg_class pc
        join pg_namespace nsp
          on pc.relnamespace = nsp.oid
      where
        pc.oid = entity
    $$;


--
-- Name: send(jsonb, text, text, boolean); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.send(payload jsonb, event text, topic text, private boolean DEFAULT true) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
  generated_id uuid;
  final_payload jsonb;
BEGIN
  BEGIN
    -- Generate a new UUID for the id
    generated_id := gen_random_uuid();

    -- Check if payload has an 'id' key, if not, add the generated UUID
    IF payload ? 'id' THEN
      final_payload := payload;
    ELSE
      final_payload := jsonb_set(payload, '{id}', to_jsonb(generated_id));
    END IF;

    -- Set the topic configuration
    EXECUTE format('SET LOCAL realtime.topic TO %L', topic);

    -- Attempt to insert the message
    INSERT INTO realtime.messages (id, payload, event, topic, private, extension)
    VALUES (generated_id, final_payload, event, topic, private, 'broadcast');
  EXCEPTION
    WHEN OTHERS THEN
      -- Capture and notify the error
      RAISE WARNING 'ErrorSendingBroadcastMessage: %', SQLERRM;
  END;
END;
$$;


--
-- Name: subscription_check_filters(); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.subscription_check_filters() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
    /*
    Validates that the user defined filters for a subscription:
    - refer to valid columns that the claimed role may access
    - values are coercable to the correct column type
    */
    declare
        col_names text[] = coalesce(
                array_agg(c.column_name order by c.ordinal_position),
                '{}'::text[]
            )
            from
                information_schema.columns c
            where
                format('%I.%I', c.table_schema, c.table_name)::regclass = new.entity
                and pg_catalog.has_column_privilege(
                    (new.claims ->> 'role'),
                    format('%I.%I', c.table_schema, c.table_name)::regclass,
                    c.column_name,
                    'SELECT'
                );
        filter realtime.user_defined_filter;
        col_type regtype;

        in_val jsonb;
    begin
        for filter in select * from unnest(new.filters) loop
            -- Filtered column is valid
            if not filter.column_name = any(col_names) then
                raise exception 'invalid column for filter %', filter.column_name;
            end if;

            -- Type is sanitized and safe for string interpolation
            col_type = (
                select atttypid::regtype
                from pg_catalog.pg_attribute
                where attrelid = new.entity
                      and attname = filter.column_name
            );
            if col_type is null then
                raise exception 'failed to lookup type for column %', filter.column_name;
            end if;

            -- Set maximum number of entries for in filter
            if filter.op = 'in'::realtime.equality_op then
                in_val = realtime.cast(filter.value, (col_type::text || '[]')::regtype);
                if coalesce(jsonb_array_length(in_val), 0) > 100 then
                    raise exception 'too many values for `in` filter. Maximum 100';
                end if;
            else
                -- raises an exception if value is not coercable to type
                perform realtime.cast(filter.value, col_type);
            end if;

        end loop;

        -- Apply consistent order to filters so the unique constraint on
        -- (subscription_id, entity, filters) can't be tricked by a different filter order
        new.filters = coalesce(
            array_agg(f order by f.column_name, f.op, f.value),
            '{}'
        ) from unnest(new.filters) f;

        return new;
    end;
    $$;


--
-- Name: to_regrole(text); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.to_regrole(role_name text) RETURNS regrole
    LANGUAGE sql IMMUTABLE
    AS $$ select role_name::regrole $$;


--
-- Name: topic(); Type: FUNCTION; Schema: realtime; Owner: -
--

CREATE FUNCTION realtime.topic() RETURNS text
    LANGUAGE sql STABLE
    AS $$
select nullif(current_setting('realtime.topic', true), '')::text;
$$;


--
-- Name: can_insert_object(text, text, uuid, jsonb); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.can_insert_object(bucketid text, name text, owner uuid, metadata jsonb) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
  INSERT INTO "storage"."objects" ("bucket_id", "name", "owner", "metadata") VALUES (bucketid, name, owner, metadata);
  -- hack to rollback the successful insert
  RAISE sqlstate 'PT200' using
  message = 'ROLLBACK',
  detail = 'rollback successful insert';
END
$$;


--
-- Name: enforce_bucket_name_length(); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.enforce_bucket_name_length() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
    if length(new.name) > 100 then
        raise exception 'bucket name "%" is too long (% characters). Max is 100.', new.name, length(new.name);
    end if;
    return new;
end;
$$;


--
-- Name: extension(text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.extension(name text) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
_parts text[];
_filename text;
BEGIN
	select string_to_array(name, '/') into _parts;
	select _parts[array_length(_parts,1)] into _filename;
	-- @todo return the last part instead of 2
	return reverse(split_part(reverse(_filename), '.', 1));
END
$$;


--
-- Name: filename(text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.filename(name text) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
_parts text[];
BEGIN
	select string_to_array(name, '/') into _parts;
	return _parts[array_length(_parts,1)];
END
$$;


--
-- Name: foldername(text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.foldername(name text) RETURNS text[]
    LANGUAGE plpgsql
    AS $$
DECLARE
_parts text[];
BEGIN
	select string_to_array(name, '/') into _parts;
	return _parts[1:array_length(_parts,1)-1];
END
$$;


--
-- Name: get_common_prefix(text, text, text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.get_common_prefix(p_key text, p_prefix text, p_delimiter text) RETURNS text
    LANGUAGE sql IMMUTABLE
    AS $$
SELECT CASE
    WHEN position(p_delimiter IN substring(p_key FROM length(p_prefix) + 1)) > 0
    THEN left(p_key, length(p_prefix) + position(p_delimiter IN substring(p_key FROM length(p_prefix) + 1)))
    ELSE NULL
END;
$$;


--
-- Name: get_size_by_bucket(); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.get_size_by_bucket() RETURNS TABLE(size bigint, bucket_id text)
    LANGUAGE plpgsql
    AS $$
BEGIN
    return query
        select sum((metadata->>'size')::int) as size, obj.bucket_id
        from "storage".objects as obj
        group by obj.bucket_id;
END
$$;


--
-- Name: list_multipart_uploads_with_delimiter(text, text, text, integer, text, text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.list_multipart_uploads_with_delimiter(bucket_id text, prefix_param text, delimiter_param text, max_keys integer DEFAULT 100, next_key_token text DEFAULT ''::text, next_upload_token text DEFAULT ''::text) RETURNS TABLE(key text, id text, created_at timestamp with time zone)
    LANGUAGE plpgsql
    AS $_$
BEGIN
    RETURN QUERY EXECUTE
        'SELECT DISTINCT ON(key COLLATE "C") * from (
            SELECT
                CASE
                    WHEN position($2 IN substring(key from length($1) + 1)) > 0 THEN
                        substring(key from 1 for length($1) + position($2 IN substring(key from length($1) + 1)))
                    ELSE
                        key
                END AS key, id, created_at
            FROM
                storage.s3_multipart_uploads
            WHERE
                bucket_id = $5 AND
                key ILIKE $1 || ''%'' AND
                CASE
                    WHEN $4 != '''' AND $6 = '''' THEN
                        CASE
                            WHEN position($2 IN substring(key from length($1) + 1)) > 0 THEN
                                substring(key from 1 for length($1) + position($2 IN substring(key from length($1) + 1))) COLLATE "C" > $4
                            ELSE
                                key COLLATE "C" > $4
                            END
                    ELSE
                        true
                END AND
                CASE
                    WHEN $6 != '''' THEN
                        id COLLATE "C" > $6
                    ELSE
                        true
                    END
            ORDER BY
                key COLLATE "C" ASC, created_at ASC) as e order by key COLLATE "C" LIMIT $3'
        USING prefix_param, delimiter_param, max_keys, next_key_token, bucket_id, next_upload_token;
END;
$_$;


--
-- Name: list_objects_with_delimiter(text, text, text, integer, text, text, text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.list_objects_with_delimiter(_bucket_id text, prefix_param text, delimiter_param text, max_keys integer DEFAULT 100, start_after text DEFAULT ''::text, next_token text DEFAULT ''::text, sort_order text DEFAULT 'asc'::text) RETURNS TABLE(name text, id uuid, metadata jsonb, updated_at timestamp with time zone, created_at timestamp with time zone, last_accessed_at timestamp with time zone)
    LANGUAGE plpgsql STABLE
    AS $_$
DECLARE
    v_peek_name TEXT;
    v_current RECORD;
    v_common_prefix TEXT;

    -- Configuration
    v_is_asc BOOLEAN;
    v_prefix TEXT;
    v_start TEXT;
    v_upper_bound TEXT;
    v_file_batch_size INT;

    -- Seek state
    v_next_seek TEXT;
    v_count INT := 0;

    -- Dynamic SQL for batch query only
    v_batch_query TEXT;

BEGIN
    -- ========================================================================
    -- INITIALIZATION
    -- ========================================================================
    v_is_asc := lower(coalesce(sort_order, 'asc')) = 'asc';
    v_prefix := coalesce(prefix_param, '');
    v_start := CASE WHEN coalesce(next_token, '') <> '' THEN next_token ELSE coalesce(start_after, '') END;
    v_file_batch_size := LEAST(GREATEST(max_keys * 2, 100), 1000);

    -- Calculate upper bound for prefix filtering (bytewise, using COLLATE "C")
    IF v_prefix = '' THEN
        v_upper_bound := NULL;
    ELSIF right(v_prefix, 1) = delimiter_param THEN
        v_upper_bound := left(v_prefix, -1) || chr(ascii(delimiter_param) + 1);
    ELSE
        v_upper_bound := left(v_prefix, -1) || chr(ascii(right(v_prefix, 1)) + 1);
    END IF;

    -- Build batch query (dynamic SQL - called infrequently, amortized over many rows)
    IF v_is_asc THEN
        IF v_upper_bound IS NOT NULL THEN
            v_batch_query := 'SELECT o.name, o.id, o.updated_at, o.created_at, o.last_accessed_at, o.metadata ' ||
                'FROM storage.objects o WHERE o.bucket_id = $1 AND o.name COLLATE "C" >= $2 ' ||
                'AND o.name COLLATE "C" < $3 ORDER BY o.name COLLATE "C" ASC LIMIT $4';
        ELSE
            v_batch_query := 'SELECT o.name, o.id, o.updated_at, o.created_at, o.last_accessed_at, o.metadata ' ||
                'FROM storage.objects o WHERE o.bucket_id = $1 AND o.name COLLATE "C" >= $2 ' ||
                'ORDER BY o.name COLLATE "C" ASC LIMIT $4';
        END IF;
    ELSE
        IF v_upper_bound IS NOT NULL THEN
            v_batch_query := 'SELECT o.name, o.id, o.updated_at, o.created_at, o.last_accessed_at, o.metadata ' ||
                'FROM storage.objects o WHERE o.bucket_id = $1 AND o.name COLLATE "C" < $2 ' ||
                'AND o.name COLLATE "C" >= $3 ORDER BY o.name COLLATE "C" DESC LIMIT $4';
        ELSE
            v_batch_query := 'SELECT o.name, o.id, o.updated_at, o.created_at, o.last_accessed_at, o.metadata ' ||
                'FROM storage.objects o WHERE o.bucket_id = $1 AND o.name COLLATE "C" < $2 ' ||
                'ORDER BY o.name COLLATE "C" DESC LIMIT $4';
        END IF;
    END IF;

    -- ========================================================================
    -- SEEK INITIALIZATION: Determine starting position
    -- ========================================================================
    IF v_start = '' THEN
        IF v_is_asc THEN
            v_next_seek := v_prefix;
        ELSE
            -- DESC without cursor: find the last item in range
            IF v_upper_bound IS NOT NULL THEN
                SELECT o.name INTO v_next_seek FROM storage.objects o
                WHERE o.bucket_id = _bucket_id AND o.name COLLATE "C" >= v_prefix AND o.name COLLATE "C" < v_upper_bound
                ORDER BY o.name COLLATE "C" DESC LIMIT 1;
            ELSIF v_prefix <> '' THEN
                SELECT o.name INTO v_next_seek FROM storage.objects o
                WHERE o.bucket_id = _bucket_id AND o.name COLLATE "C" >= v_prefix
                ORDER BY o.name COLLATE "C" DESC LIMIT 1;
            ELSE
                SELECT o.name INTO v_next_seek FROM storage.objects o
                WHERE o.bucket_id = _bucket_id
                ORDER BY o.name COLLATE "C" DESC LIMIT 1;
            END IF;

            IF v_next_seek IS NOT NULL THEN
                v_next_seek := v_next_seek || delimiter_param;
            ELSE
                RETURN;
            END IF;
        END IF;
    ELSE
        -- Cursor provided: determine if it refers to a folder or leaf
        IF EXISTS (
            SELECT 1 FROM storage.objects o
            WHERE o.bucket_id = _bucket_id
              AND o.name COLLATE "C" LIKE v_start || delimiter_param || '%'
            LIMIT 1
        ) THEN
            -- Cursor refers to a folder
            IF v_is_asc THEN
                v_next_seek := v_start || chr(ascii(delimiter_param) + 1);
            ELSE
                v_next_seek := v_start || delimiter_param;
            END IF;
        ELSE
            -- Cursor refers to a leaf object
            IF v_is_asc THEN
                v_next_seek := v_start || delimiter_param;
            ELSE
                v_next_seek := v_start;
            END IF;
        END IF;
    END IF;

    -- ========================================================================
    -- MAIN LOOP: Hybrid peek-then-batch algorithm
    -- Uses STATIC SQL for peek (hot path) and DYNAMIC SQL for batch
    -- ========================================================================
    LOOP
        EXIT WHEN v_count >= max_keys;

        -- STEP 1: PEEK using STATIC SQL (plan cached, very fast)
        IF v_is_asc THEN
            IF v_upper_bound IS NOT NULL THEN
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = _bucket_id AND o.name COLLATE "C" >= v_next_seek AND o.name COLLATE "C" < v_upper_bound
                ORDER BY o.name COLLATE "C" ASC LIMIT 1;
            ELSE
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = _bucket_id AND o.name COLLATE "C" >= v_next_seek
                ORDER BY o.name COLLATE "C" ASC LIMIT 1;
            END IF;
        ELSE
            IF v_upper_bound IS NOT NULL THEN
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = _bucket_id AND o.name COLLATE "C" < v_next_seek AND o.name COLLATE "C" >= v_prefix
                ORDER BY o.name COLLATE "C" DESC LIMIT 1;
            ELSIF v_prefix <> '' THEN
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = _bucket_id AND o.name COLLATE "C" < v_next_seek AND o.name COLLATE "C" >= v_prefix
                ORDER BY o.name COLLATE "C" DESC LIMIT 1;
            ELSE
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = _bucket_id AND o.name COLLATE "C" < v_next_seek
                ORDER BY o.name COLLATE "C" DESC LIMIT 1;
            END IF;
        END IF;

        EXIT WHEN v_peek_name IS NULL;

        -- STEP 2: Check if this is a FOLDER or FILE
        v_common_prefix := storage.get_common_prefix(v_peek_name, v_prefix, delimiter_param);

        IF v_common_prefix IS NOT NULL THEN
            -- FOLDER: Emit and skip to next folder (no heap access needed)
            name := rtrim(v_common_prefix, delimiter_param);
            id := NULL;
            updated_at := NULL;
            created_at := NULL;
            last_accessed_at := NULL;
            metadata := NULL;
            RETURN NEXT;
            v_count := v_count + 1;

            -- Advance seek past the folder range
            IF v_is_asc THEN
                v_next_seek := left(v_common_prefix, -1) || chr(ascii(delimiter_param) + 1);
            ELSE
                v_next_seek := v_common_prefix;
            END IF;
        ELSE
            -- FILE: Batch fetch using DYNAMIC SQL (overhead amortized over many rows)
            -- For ASC: upper_bound is the exclusive upper limit (< condition)
            -- For DESC: prefix is the inclusive lower limit (>= condition)
            FOR v_current IN EXECUTE v_batch_query USING _bucket_id, v_next_seek,
                CASE WHEN v_is_asc THEN COALESCE(v_upper_bound, v_prefix) ELSE v_prefix END, v_file_batch_size
            LOOP
                v_common_prefix := storage.get_common_prefix(v_current.name, v_prefix, delimiter_param);

                IF v_common_prefix IS NOT NULL THEN
                    -- Hit a folder: exit batch, let peek handle it
                    v_next_seek := v_current.name;
                    EXIT;
                END IF;

                -- Emit file
                name := v_current.name;
                id := v_current.id;
                updated_at := v_current.updated_at;
                created_at := v_current.created_at;
                last_accessed_at := v_current.last_accessed_at;
                metadata := v_current.metadata;
                RETURN NEXT;
                v_count := v_count + 1;

                -- Advance seek past this file
                IF v_is_asc THEN
                    v_next_seek := v_current.name || delimiter_param;
                ELSE
                    v_next_seek := v_current.name;
                END IF;

                EXIT WHEN v_count >= max_keys;
            END LOOP;
        END IF;
    END LOOP;
END;
$_$;


--
-- Name: operation(); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.operation() RETURNS text
    LANGUAGE plpgsql STABLE
    AS $$
BEGIN
    RETURN current_setting('storage.operation', true);
END;
$$;


--
-- Name: protect_delete(); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.protect_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Check if storage.allow_delete_query is set to 'true'
    IF COALESCE(current_setting('storage.allow_delete_query', true), 'false') != 'true' THEN
        RAISE EXCEPTION 'Direct deletion from storage tables is not allowed. Use the Storage API instead.'
            USING HINT = 'This prevents accidental data loss from orphaned objects.',
                  ERRCODE = '42501';
    END IF;
    RETURN NULL;
END;
$$;


--
-- Name: search(text, text, integer, integer, integer, text, text, text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.search(prefix text, bucketname text, limits integer DEFAULT 100, levels integer DEFAULT 1, offsets integer DEFAULT 0, search text DEFAULT ''::text, sortcolumn text DEFAULT 'name'::text, sortorder text DEFAULT 'asc'::text) RETURNS TABLE(name text, id uuid, updated_at timestamp with time zone, created_at timestamp with time zone, last_accessed_at timestamp with time zone, metadata jsonb)
    LANGUAGE plpgsql STABLE
    AS $_$
DECLARE
    v_peek_name TEXT;
    v_current RECORD;
    v_common_prefix TEXT;
    v_delimiter CONSTANT TEXT := '/';

    -- Configuration
    v_limit INT;
    v_prefix TEXT;
    v_prefix_lower TEXT;
    v_is_asc BOOLEAN;
    v_order_by TEXT;
    v_sort_order TEXT;
    v_upper_bound TEXT;
    v_file_batch_size INT;

    -- Dynamic SQL for batch query only
    v_batch_query TEXT;

    -- Seek state
    v_next_seek TEXT;
    v_count INT := 0;
    v_skipped INT := 0;
BEGIN
    -- ========================================================================
    -- INITIALIZATION
    -- ========================================================================
    v_limit := LEAST(coalesce(limits, 100), 1500);
    v_prefix := coalesce(prefix, '') || coalesce(search, '');
    v_prefix_lower := lower(v_prefix);
    v_is_asc := lower(coalesce(sortorder, 'asc')) = 'asc';
    v_file_batch_size := LEAST(GREATEST(v_limit * 2, 100), 1000);

    -- Validate sort column
    CASE lower(coalesce(sortcolumn, 'name'))
        WHEN 'name' THEN v_order_by := 'name';
        WHEN 'updated_at' THEN v_order_by := 'updated_at';
        WHEN 'created_at' THEN v_order_by := 'created_at';
        WHEN 'last_accessed_at' THEN v_order_by := 'last_accessed_at';
        ELSE v_order_by := 'name';
    END CASE;

    v_sort_order := CASE WHEN v_is_asc THEN 'asc' ELSE 'desc' END;

    -- ========================================================================
    -- NON-NAME SORTING: Use path_tokens approach (unchanged)
    -- ========================================================================
    IF v_order_by != 'name' THEN
        RETURN QUERY EXECUTE format(
            $sql$
            WITH folders AS (
                SELECT path_tokens[$1] AS folder
                FROM storage.objects
                WHERE objects.name ILIKE $2 || '%%'
                  AND bucket_id = $3
                  AND array_length(objects.path_tokens, 1) <> $1
                GROUP BY folder
                ORDER BY folder %s
            )
            (SELECT folder AS "name",
                   NULL::uuid AS id,
                   NULL::timestamptz AS updated_at,
                   NULL::timestamptz AS created_at,
                   NULL::timestamptz AS last_accessed_at,
                   NULL::jsonb AS metadata FROM folders)
            UNION ALL
            (SELECT path_tokens[$1] AS "name",
                   id, updated_at, created_at, last_accessed_at, metadata
             FROM storage.objects
             WHERE objects.name ILIKE $2 || '%%'
               AND bucket_id = $3
               AND array_length(objects.path_tokens, 1) = $1
             ORDER BY %I %s)
            LIMIT $4 OFFSET $5
            $sql$, v_sort_order, v_order_by, v_sort_order
        ) USING levels, v_prefix, bucketname, v_limit, offsets;
        RETURN;
    END IF;

    -- ========================================================================
    -- NAME SORTING: Hybrid skip-scan with batch optimization
    -- ========================================================================

    -- Calculate upper bound for prefix filtering
    IF v_prefix_lower = '' THEN
        v_upper_bound := NULL;
    ELSIF right(v_prefix_lower, 1) = v_delimiter THEN
        v_upper_bound := left(v_prefix_lower, -1) || chr(ascii(v_delimiter) + 1);
    ELSE
        v_upper_bound := left(v_prefix_lower, -1) || chr(ascii(right(v_prefix_lower, 1)) + 1);
    END IF;

    -- Build batch query (dynamic SQL - called infrequently, amortized over many rows)
    IF v_is_asc THEN
        IF v_upper_bound IS NOT NULL THEN
            v_batch_query := 'SELECT o.name, o.id, o.updated_at, o.created_at, o.last_accessed_at, o.metadata ' ||
                'FROM storage.objects o WHERE o.bucket_id = $1 AND lower(o.name) COLLATE "C" >= $2 ' ||
                'AND lower(o.name) COLLATE "C" < $3 ORDER BY lower(o.name) COLLATE "C" ASC LIMIT $4';
        ELSE
            v_batch_query := 'SELECT o.name, o.id, o.updated_at, o.created_at, o.last_accessed_at, o.metadata ' ||
                'FROM storage.objects o WHERE o.bucket_id = $1 AND lower(o.name) COLLATE "C" >= $2 ' ||
                'ORDER BY lower(o.name) COLLATE "C" ASC LIMIT $4';
        END IF;
    ELSE
        IF v_upper_bound IS NOT NULL THEN
            v_batch_query := 'SELECT o.name, o.id, o.updated_at, o.created_at, o.last_accessed_at, o.metadata ' ||
                'FROM storage.objects o WHERE o.bucket_id = $1 AND lower(o.name) COLLATE "C" < $2 ' ||
                'AND lower(o.name) COLLATE "C" >= $3 ORDER BY lower(o.name) COLLATE "C" DESC LIMIT $4';
        ELSE
            v_batch_query := 'SELECT o.name, o.id, o.updated_at, o.created_at, o.last_accessed_at, o.metadata ' ||
                'FROM storage.objects o WHERE o.bucket_id = $1 AND lower(o.name) COLLATE "C" < $2 ' ||
                'ORDER BY lower(o.name) COLLATE "C" DESC LIMIT $4';
        END IF;
    END IF;

    -- Initialize seek position
    IF v_is_asc THEN
        v_next_seek := v_prefix_lower;
    ELSE
        -- DESC: find the last item in range first (static SQL)
        IF v_upper_bound IS NOT NULL THEN
            SELECT o.name INTO v_peek_name FROM storage.objects o
            WHERE o.bucket_id = bucketname AND lower(o.name) COLLATE "C" >= v_prefix_lower AND lower(o.name) COLLATE "C" < v_upper_bound
            ORDER BY lower(o.name) COLLATE "C" DESC LIMIT 1;
        ELSIF v_prefix_lower <> '' THEN
            SELECT o.name INTO v_peek_name FROM storage.objects o
            WHERE o.bucket_id = bucketname AND lower(o.name) COLLATE "C" >= v_prefix_lower
            ORDER BY lower(o.name) COLLATE "C" DESC LIMIT 1;
        ELSE
            SELECT o.name INTO v_peek_name FROM storage.objects o
            WHERE o.bucket_id = bucketname
            ORDER BY lower(o.name) COLLATE "C" DESC LIMIT 1;
        END IF;

        IF v_peek_name IS NOT NULL THEN
            v_next_seek := lower(v_peek_name) || v_delimiter;
        ELSE
            RETURN;
        END IF;
    END IF;

    -- ========================================================================
    -- MAIN LOOP: Hybrid peek-then-batch algorithm
    -- Uses STATIC SQL for peek (hot path) and DYNAMIC SQL for batch
    -- ========================================================================
    LOOP
        EXIT WHEN v_count >= v_limit;

        -- STEP 1: PEEK using STATIC SQL (plan cached, very fast)
        IF v_is_asc THEN
            IF v_upper_bound IS NOT NULL THEN
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = bucketname AND lower(o.name) COLLATE "C" >= v_next_seek AND lower(o.name) COLLATE "C" < v_upper_bound
                ORDER BY lower(o.name) COLLATE "C" ASC LIMIT 1;
            ELSE
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = bucketname AND lower(o.name) COLLATE "C" >= v_next_seek
                ORDER BY lower(o.name) COLLATE "C" ASC LIMIT 1;
            END IF;
        ELSE
            IF v_upper_bound IS NOT NULL THEN
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = bucketname AND lower(o.name) COLLATE "C" < v_next_seek AND lower(o.name) COLLATE "C" >= v_prefix_lower
                ORDER BY lower(o.name) COLLATE "C" DESC LIMIT 1;
            ELSIF v_prefix_lower <> '' THEN
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = bucketname AND lower(o.name) COLLATE "C" < v_next_seek AND lower(o.name) COLLATE "C" >= v_prefix_lower
                ORDER BY lower(o.name) COLLATE "C" DESC LIMIT 1;
            ELSE
                SELECT o.name INTO v_peek_name FROM storage.objects o
                WHERE o.bucket_id = bucketname AND lower(o.name) COLLATE "C" < v_next_seek
                ORDER BY lower(o.name) COLLATE "C" DESC LIMIT 1;
            END IF;
        END IF;

        EXIT WHEN v_peek_name IS NULL;

        -- STEP 2: Check if this is a FOLDER or FILE
        v_common_prefix := storage.get_common_prefix(lower(v_peek_name), v_prefix_lower, v_delimiter);

        IF v_common_prefix IS NOT NULL THEN
            -- FOLDER: Handle offset, emit if needed, skip to next folder
            IF v_skipped < offsets THEN
                v_skipped := v_skipped + 1;
            ELSE
                name := split_part(rtrim(storage.get_common_prefix(v_peek_name, v_prefix, v_delimiter), v_delimiter), v_delimiter, levels);
                id := NULL;
                updated_at := NULL;
                created_at := NULL;
                last_accessed_at := NULL;
                metadata := NULL;
                RETURN NEXT;
                v_count := v_count + 1;
            END IF;

            -- Advance seek past the folder range
            IF v_is_asc THEN
                v_next_seek := lower(left(v_common_prefix, -1)) || chr(ascii(v_delimiter) + 1);
            ELSE
                v_next_seek := lower(v_common_prefix);
            END IF;
        ELSE
            -- FILE: Batch fetch using DYNAMIC SQL (overhead amortized over many rows)
            -- For ASC: upper_bound is the exclusive upper limit (< condition)
            -- For DESC: prefix_lower is the inclusive lower limit (>= condition)
            FOR v_current IN EXECUTE v_batch_query
                USING bucketname, v_next_seek,
                    CASE WHEN v_is_asc THEN COALESCE(v_upper_bound, v_prefix_lower) ELSE v_prefix_lower END, v_file_batch_size
            LOOP
                v_common_prefix := storage.get_common_prefix(lower(v_current.name), v_prefix_lower, v_delimiter);

                IF v_common_prefix IS NOT NULL THEN
                    -- Hit a folder: exit batch, let peek handle it
                    v_next_seek := lower(v_current.name);
                    EXIT;
                END IF;

                -- Handle offset skipping
                IF v_skipped < offsets THEN
                    v_skipped := v_skipped + 1;
                ELSE
                    -- Emit file
                    name := split_part(v_current.name, v_delimiter, levels);
                    id := v_current.id;
                    updated_at := v_current.updated_at;
                    created_at := v_current.created_at;
                    last_accessed_at := v_current.last_accessed_at;
                    metadata := v_current.metadata;
                    RETURN NEXT;
                    v_count := v_count + 1;
                END IF;

                -- Advance seek past this file
                IF v_is_asc THEN
                    v_next_seek := lower(v_current.name) || v_delimiter;
                ELSE
                    v_next_seek := lower(v_current.name);
                END IF;

                EXIT WHEN v_count >= v_limit;
            END LOOP;
        END IF;
    END LOOP;
END;
$_$;


--
-- Name: search_by_timestamp(text, text, integer, integer, text, text, text, text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.search_by_timestamp(p_prefix text, p_bucket_id text, p_limit integer, p_level integer, p_start_after text, p_sort_order text, p_sort_column text, p_sort_column_after text) RETURNS TABLE(key text, name text, id uuid, updated_at timestamp with time zone, created_at timestamp with time zone, last_accessed_at timestamp with time zone, metadata jsonb)
    LANGUAGE plpgsql STABLE
    AS $_$
DECLARE
    v_cursor_op text;
    v_query text;
    v_prefix text;
BEGIN
    v_prefix := coalesce(p_prefix, '');

    IF p_sort_order = 'asc' THEN
        v_cursor_op := '>';
    ELSE
        v_cursor_op := '<';
    END IF;

    v_query := format($sql$
        WITH raw_objects AS (
            SELECT
                o.name AS obj_name,
                o.id AS obj_id,
                o.updated_at AS obj_updated_at,
                o.created_at AS obj_created_at,
                o.last_accessed_at AS obj_last_accessed_at,
                o.metadata AS obj_metadata,
                storage.get_common_prefix(o.name, $1, '/') AS common_prefix
            FROM storage.objects o
            WHERE o.bucket_id = $2
              AND o.name COLLATE "C" LIKE $1 || '%%'
        ),
        -- Aggregate common prefixes (folders)
        -- Both created_at and updated_at use MIN(obj_created_at) to match the old prefixes table behavior
        aggregated_prefixes AS (
            SELECT
                rtrim(common_prefix, '/') AS name,
                NULL::uuid AS id,
                MIN(obj_created_at) AS updated_at,
                MIN(obj_created_at) AS created_at,
                NULL::timestamptz AS last_accessed_at,
                NULL::jsonb AS metadata,
                TRUE AS is_prefix
            FROM raw_objects
            WHERE common_prefix IS NOT NULL
            GROUP BY common_prefix
        ),
        leaf_objects AS (
            SELECT
                obj_name AS name,
                obj_id AS id,
                obj_updated_at AS updated_at,
                obj_created_at AS created_at,
                obj_last_accessed_at AS last_accessed_at,
                obj_metadata AS metadata,
                FALSE AS is_prefix
            FROM raw_objects
            WHERE common_prefix IS NULL
        ),
        combined AS (
            SELECT * FROM aggregated_prefixes
            UNION ALL
            SELECT * FROM leaf_objects
        ),
        filtered AS (
            SELECT *
            FROM combined
            WHERE (
                $5 = ''
                OR ROW(
                    date_trunc('milliseconds', %I),
                    name COLLATE "C"
                ) %s ROW(
                    COALESCE(NULLIF($6, '')::timestamptz, 'epoch'::timestamptz),
                    $5
                )
            )
        )
        SELECT
            split_part(name, '/', $3) AS key,
            name,
            id,
            updated_at,
            created_at,
            last_accessed_at,
            metadata
        FROM filtered
        ORDER BY
            COALESCE(date_trunc('milliseconds', %I), 'epoch'::timestamptz) %s,
            name COLLATE "C" %s
        LIMIT $4
    $sql$,
        p_sort_column,
        v_cursor_op,
        p_sort_column,
        p_sort_order,
        p_sort_order
    );

    RETURN QUERY EXECUTE v_query
    USING v_prefix, p_bucket_id, p_level, p_limit, p_start_after, p_sort_column_after;
END;
$_$;


--
-- Name: search_v2(text, text, integer, integer, text, text, text, text); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.search_v2(prefix text, bucket_name text, limits integer DEFAULT 100, levels integer DEFAULT 1, start_after text DEFAULT ''::text, sort_order text DEFAULT 'asc'::text, sort_column text DEFAULT 'name'::text, sort_column_after text DEFAULT ''::text) RETURNS TABLE(key text, name text, id uuid, updated_at timestamp with time zone, created_at timestamp with time zone, last_accessed_at timestamp with time zone, metadata jsonb)
    LANGUAGE plpgsql STABLE
    AS $$
DECLARE
    v_sort_col text;
    v_sort_ord text;
    v_limit int;
BEGIN
    -- Cap limit to maximum of 1500 records
    v_limit := LEAST(coalesce(limits, 100), 1500);

    -- Validate and normalize sort_order
    v_sort_ord := lower(coalesce(sort_order, 'asc'));
    IF v_sort_ord NOT IN ('asc', 'desc') THEN
        v_sort_ord := 'asc';
    END IF;

    -- Validate and normalize sort_column
    v_sort_col := lower(coalesce(sort_column, 'name'));
    IF v_sort_col NOT IN ('name', 'updated_at', 'created_at') THEN
        v_sort_col := 'name';
    END IF;

    -- Route to appropriate implementation
    IF v_sort_col = 'name' THEN
        -- Use list_objects_with_delimiter for name sorting (most efficient: O(k * log n))
        RETURN QUERY
        SELECT
            split_part(l.name, '/', levels) AS key,
            l.name AS name,
            l.id,
            l.updated_at,
            l.created_at,
            l.last_accessed_at,
            l.metadata
        FROM storage.list_objects_with_delimiter(
            bucket_name,
            coalesce(prefix, ''),
            '/',
            v_limit,
            start_after,
            '',
            v_sort_ord
        ) l;
    ELSE
        -- Use aggregation approach for timestamp sorting
        -- Not efficient for large datasets but supports correct pagination
        RETURN QUERY SELECT * FROM storage.search_by_timestamp(
            prefix, bucket_name, v_limit, levels, start_after,
            v_sort_ord, v_sort_col, sort_column_after
        );
    END IF;
END;
$$;


--
-- Name: update_updated_at_column(); Type: FUNCTION; Schema: storage; Owner: -
--

CREATE FUNCTION storage.update_updated_at_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW; 
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: audit_log_entries; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.audit_log_entries (
    instance_id uuid,
    id uuid NOT NULL,
    payload json,
    created_at timestamp with time zone,
    ip_address character varying(64) DEFAULT ''::character varying NOT NULL
);


--
-- Name: TABLE audit_log_entries; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.audit_log_entries IS 'Auth: Audit trail for user actions.';


--
-- Name: custom_oauth_providers; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.custom_oauth_providers (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    provider_type text NOT NULL,
    identifier text NOT NULL,
    name text NOT NULL,
    client_id text NOT NULL,
    client_secret text NOT NULL,
    acceptable_client_ids text[] DEFAULT '{}'::text[] NOT NULL,
    scopes text[] DEFAULT '{}'::text[] NOT NULL,
    pkce_enabled boolean DEFAULT true NOT NULL,
    attribute_mapping jsonb DEFAULT '{}'::jsonb NOT NULL,
    authorization_params jsonb DEFAULT '{}'::jsonb NOT NULL,
    enabled boolean DEFAULT true NOT NULL,
    email_optional boolean DEFAULT false NOT NULL,
    issuer text,
    discovery_url text,
    skip_nonce_check boolean DEFAULT false NOT NULL,
    cached_discovery jsonb,
    discovery_cached_at timestamp with time zone,
    authorization_url text,
    token_url text,
    userinfo_url text,
    jwks_uri text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT custom_oauth_providers_authorization_url_https CHECK (((authorization_url IS NULL) OR (authorization_url ~~ 'https://%'::text))),
    CONSTRAINT custom_oauth_providers_authorization_url_length CHECK (((authorization_url IS NULL) OR (char_length(authorization_url) <= 2048))),
    CONSTRAINT custom_oauth_providers_client_id_length CHECK (((char_length(client_id) >= 1) AND (char_length(client_id) <= 512))),
    CONSTRAINT custom_oauth_providers_discovery_url_length CHECK (((discovery_url IS NULL) OR (char_length(discovery_url) <= 2048))),
    CONSTRAINT custom_oauth_providers_identifier_format CHECK ((identifier ~ '^[a-z0-9][a-z0-9:-]{0,48}[a-z0-9]$'::text)),
    CONSTRAINT custom_oauth_providers_issuer_length CHECK (((issuer IS NULL) OR ((char_length(issuer) >= 1) AND (char_length(issuer) <= 2048)))),
    CONSTRAINT custom_oauth_providers_jwks_uri_https CHECK (((jwks_uri IS NULL) OR (jwks_uri ~~ 'https://%'::text))),
    CONSTRAINT custom_oauth_providers_jwks_uri_length CHECK (((jwks_uri IS NULL) OR (char_length(jwks_uri) <= 2048))),
    CONSTRAINT custom_oauth_providers_name_length CHECK (((char_length(name) >= 1) AND (char_length(name) <= 100))),
    CONSTRAINT custom_oauth_providers_oauth2_requires_endpoints CHECK (((provider_type <> 'oauth2'::text) OR ((authorization_url IS NOT NULL) AND (token_url IS NOT NULL) AND (userinfo_url IS NOT NULL)))),
    CONSTRAINT custom_oauth_providers_oidc_discovery_url_https CHECK (((provider_type <> 'oidc'::text) OR (discovery_url IS NULL) OR (discovery_url ~~ 'https://%'::text))),
    CONSTRAINT custom_oauth_providers_oidc_issuer_https CHECK (((provider_type <> 'oidc'::text) OR (issuer IS NULL) OR (issuer ~~ 'https://%'::text))),
    CONSTRAINT custom_oauth_providers_oidc_requires_issuer CHECK (((provider_type <> 'oidc'::text) OR (issuer IS NOT NULL))),
    CONSTRAINT custom_oauth_providers_provider_type_check CHECK ((provider_type = ANY (ARRAY['oauth2'::text, 'oidc'::text]))),
    CONSTRAINT custom_oauth_providers_token_url_https CHECK (((token_url IS NULL) OR (token_url ~~ 'https://%'::text))),
    CONSTRAINT custom_oauth_providers_token_url_length CHECK (((token_url IS NULL) OR (char_length(token_url) <= 2048))),
    CONSTRAINT custom_oauth_providers_userinfo_url_https CHECK (((userinfo_url IS NULL) OR (userinfo_url ~~ 'https://%'::text))),
    CONSTRAINT custom_oauth_providers_userinfo_url_length CHECK (((userinfo_url IS NULL) OR (char_length(userinfo_url) <= 2048)))
);


--
-- Name: flow_state; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.flow_state (
    id uuid NOT NULL,
    user_id uuid,
    auth_code text,
    code_challenge_method auth.code_challenge_method,
    code_challenge text,
    provider_type text NOT NULL,
    provider_access_token text,
    provider_refresh_token text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    authentication_method text NOT NULL,
    auth_code_issued_at timestamp with time zone,
    invite_token text,
    referrer text,
    oauth_client_state_id uuid,
    linking_target_id uuid,
    email_optional boolean DEFAULT false NOT NULL
);


--
-- Name: TABLE flow_state; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.flow_state IS 'Stores metadata for all OAuth/SSO login flows';


--
-- Name: identities; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.identities (
    provider_id text NOT NULL,
    user_id uuid NOT NULL,
    identity_data jsonb NOT NULL,
    provider text NOT NULL,
    last_sign_in_at timestamp with time zone,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    email text GENERATED ALWAYS AS (lower((identity_data ->> 'email'::text))) STORED,
    id uuid DEFAULT gen_random_uuid() NOT NULL
);


--
-- Name: TABLE identities; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.identities IS 'Auth: Stores identities associated to a user.';


--
-- Name: COLUMN identities.email; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.identities.email IS 'Auth: Email is a generated column that references the optional email property in the identity_data';


--
-- Name: instances; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.instances (
    id uuid NOT NULL,
    uuid uuid,
    raw_base_config text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone
);


--
-- Name: TABLE instances; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.instances IS 'Auth: Manages users across multiple sites.';


--
-- Name: mfa_amr_claims; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.mfa_amr_claims (
    session_id uuid NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    authentication_method text NOT NULL,
    id uuid NOT NULL
);


--
-- Name: TABLE mfa_amr_claims; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.mfa_amr_claims IS 'auth: stores authenticator method reference claims for multi factor authentication';


--
-- Name: mfa_challenges; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.mfa_challenges (
    id uuid NOT NULL,
    factor_id uuid NOT NULL,
    created_at timestamp with time zone NOT NULL,
    verified_at timestamp with time zone,
    ip_address inet NOT NULL,
    otp_code text,
    web_authn_session_data jsonb
);


--
-- Name: TABLE mfa_challenges; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.mfa_challenges IS 'auth: stores metadata about challenge requests made';


--
-- Name: mfa_factors; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.mfa_factors (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    friendly_name text,
    factor_type auth.factor_type NOT NULL,
    status auth.factor_status NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    secret text,
    phone text,
    last_challenged_at timestamp with time zone,
    web_authn_credential jsonb,
    web_authn_aaguid uuid,
    last_webauthn_challenge_data jsonb
);


--
-- Name: TABLE mfa_factors; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.mfa_factors IS 'auth: stores metadata about factors';


--
-- Name: COLUMN mfa_factors.last_webauthn_challenge_data; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.mfa_factors.last_webauthn_challenge_data IS 'Stores the latest WebAuthn challenge data including attestation/assertion for customer verification';


--
-- Name: oauth_authorizations; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.oauth_authorizations (
    id uuid NOT NULL,
    authorization_id text NOT NULL,
    client_id uuid NOT NULL,
    user_id uuid,
    redirect_uri text NOT NULL,
    scope text NOT NULL,
    state text,
    resource text,
    code_challenge text,
    code_challenge_method auth.code_challenge_method,
    response_type auth.oauth_response_type DEFAULT 'code'::auth.oauth_response_type NOT NULL,
    status auth.oauth_authorization_status DEFAULT 'pending'::auth.oauth_authorization_status NOT NULL,
    authorization_code text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    expires_at timestamp with time zone DEFAULT (now() + '00:03:00'::interval) NOT NULL,
    approved_at timestamp with time zone,
    nonce text,
    CONSTRAINT oauth_authorizations_authorization_code_length CHECK ((char_length(authorization_code) <= 255)),
    CONSTRAINT oauth_authorizations_code_challenge_length CHECK ((char_length(code_challenge) <= 128)),
    CONSTRAINT oauth_authorizations_expires_at_future CHECK ((expires_at > created_at)),
    CONSTRAINT oauth_authorizations_nonce_length CHECK ((char_length(nonce) <= 255)),
    CONSTRAINT oauth_authorizations_redirect_uri_length CHECK ((char_length(redirect_uri) <= 2048)),
    CONSTRAINT oauth_authorizations_resource_length CHECK ((char_length(resource) <= 2048)),
    CONSTRAINT oauth_authorizations_scope_length CHECK ((char_length(scope) <= 4096)),
    CONSTRAINT oauth_authorizations_state_length CHECK ((char_length(state) <= 4096))
);


--
-- Name: oauth_client_states; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.oauth_client_states (
    id uuid NOT NULL,
    provider_type text NOT NULL,
    code_verifier text,
    created_at timestamp with time zone NOT NULL
);


--
-- Name: TABLE oauth_client_states; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.oauth_client_states IS 'Stores OAuth states for third-party provider authentication flows where Supabase acts as the OAuth client.';


--
-- Name: oauth_clients; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.oauth_clients (
    id uuid NOT NULL,
    client_secret_hash text,
    registration_type auth.oauth_registration_type NOT NULL,
    redirect_uris text NOT NULL,
    grant_types text NOT NULL,
    client_name text,
    client_uri text,
    logo_uri text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone,
    client_type auth.oauth_client_type DEFAULT 'confidential'::auth.oauth_client_type NOT NULL,
    token_endpoint_auth_method text NOT NULL,
    CONSTRAINT oauth_clients_client_name_length CHECK ((char_length(client_name) <= 1024)),
    CONSTRAINT oauth_clients_client_uri_length CHECK ((char_length(client_uri) <= 2048)),
    CONSTRAINT oauth_clients_logo_uri_length CHECK ((char_length(logo_uri) <= 2048)),
    CONSTRAINT oauth_clients_token_endpoint_auth_method_check CHECK ((token_endpoint_auth_method = ANY (ARRAY['client_secret_basic'::text, 'client_secret_post'::text, 'none'::text])))
);


--
-- Name: oauth_consents; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.oauth_consents (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    client_id uuid NOT NULL,
    scopes text NOT NULL,
    granted_at timestamp with time zone DEFAULT now() NOT NULL,
    revoked_at timestamp with time zone,
    CONSTRAINT oauth_consents_revoked_after_granted CHECK (((revoked_at IS NULL) OR (revoked_at >= granted_at))),
    CONSTRAINT oauth_consents_scopes_length CHECK ((char_length(scopes) <= 2048)),
    CONSTRAINT oauth_consents_scopes_not_empty CHECK ((char_length(TRIM(BOTH FROM scopes)) > 0))
);


--
-- Name: one_time_tokens; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.one_time_tokens (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    token_type auth.one_time_token_type NOT NULL,
    token_hash text NOT NULL,
    relates_to text NOT NULL,
    created_at timestamp without time zone DEFAULT now() NOT NULL,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    CONSTRAINT one_time_tokens_token_hash_check CHECK ((char_length(token_hash) > 0))
);


--
-- Name: refresh_tokens; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.refresh_tokens (
    instance_id uuid,
    id bigint NOT NULL,
    token character varying(255),
    user_id character varying(255),
    revoked boolean,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    parent character varying(255),
    session_id uuid
);


--
-- Name: TABLE refresh_tokens; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.refresh_tokens IS 'Auth: Store of tokens used to refresh JWT tokens once they expire.';


--
-- Name: refresh_tokens_id_seq; Type: SEQUENCE; Schema: auth; Owner: -
--

CREATE SEQUENCE auth.refresh_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: refresh_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: auth; Owner: -
--

ALTER SEQUENCE auth.refresh_tokens_id_seq OWNED BY auth.refresh_tokens.id;


--
-- Name: saml_providers; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.saml_providers (
    id uuid NOT NULL,
    sso_provider_id uuid NOT NULL,
    entity_id text NOT NULL,
    metadata_xml text NOT NULL,
    metadata_url text,
    attribute_mapping jsonb,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    name_id_format text,
    CONSTRAINT "entity_id not empty" CHECK ((char_length(entity_id) > 0)),
    CONSTRAINT "metadata_url not empty" CHECK (((metadata_url = NULL::text) OR (char_length(metadata_url) > 0))),
    CONSTRAINT "metadata_xml not empty" CHECK ((char_length(metadata_xml) > 0))
);


--
-- Name: TABLE saml_providers; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.saml_providers IS 'Auth: Manages SAML Identity Provider connections.';


--
-- Name: saml_relay_states; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.saml_relay_states (
    id uuid NOT NULL,
    sso_provider_id uuid NOT NULL,
    request_id text NOT NULL,
    for_email text,
    redirect_to text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    flow_state_id uuid,
    CONSTRAINT "request_id not empty" CHECK ((char_length(request_id) > 0))
);


--
-- Name: TABLE saml_relay_states; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.saml_relay_states IS 'Auth: Contains SAML Relay State information for each Service Provider initiated login.';


--
-- Name: schema_migrations; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.schema_migrations (
    version character varying(255) NOT NULL
);


--
-- Name: TABLE schema_migrations; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.schema_migrations IS 'Auth: Manages updates to the auth system.';


--
-- Name: sessions; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.sessions (
    id uuid NOT NULL,
    user_id uuid NOT NULL,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    factor_id uuid,
    aal auth.aal_level,
    not_after timestamp with time zone,
    refreshed_at timestamp without time zone,
    user_agent text,
    ip inet,
    tag text,
    oauth_client_id uuid,
    refresh_token_hmac_key text,
    refresh_token_counter bigint,
    scopes text,
    CONSTRAINT sessions_scopes_length CHECK ((char_length(scopes) <= 4096))
);


--
-- Name: TABLE sessions; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.sessions IS 'Auth: Stores session data associated to a user.';


--
-- Name: COLUMN sessions.not_after; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.sessions.not_after IS 'Auth: Not after is a nullable column that contains a timestamp after which the session should be regarded as expired.';


--
-- Name: COLUMN sessions.refresh_token_hmac_key; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.sessions.refresh_token_hmac_key IS 'Holds a HMAC-SHA256 key used to sign refresh tokens for this session.';


--
-- Name: COLUMN sessions.refresh_token_counter; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.sessions.refresh_token_counter IS 'Holds the ID (counter) of the last issued refresh token.';


--
-- Name: sso_domains; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.sso_domains (
    id uuid NOT NULL,
    sso_provider_id uuid NOT NULL,
    domain text NOT NULL,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    CONSTRAINT "domain not empty" CHECK ((char_length(domain) > 0))
);


--
-- Name: TABLE sso_domains; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.sso_domains IS 'Auth: Manages SSO email address domain mapping to an SSO Identity Provider.';


--
-- Name: sso_providers; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.sso_providers (
    id uuid NOT NULL,
    resource_id text,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    disabled boolean,
    CONSTRAINT "resource_id not empty" CHECK (((resource_id = NULL::text) OR (char_length(resource_id) > 0)))
);


--
-- Name: TABLE sso_providers; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.sso_providers IS 'Auth: Manages SSO identity provider information; see saml_providers for SAML.';


--
-- Name: COLUMN sso_providers.resource_id; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.sso_providers.resource_id IS 'Auth: Uniquely identifies a SSO provider according to a user-chosen resource ID (case insensitive), useful in infrastructure as code.';


--
-- Name: users; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.users (
    instance_id uuid,
    id uuid NOT NULL,
    aud character varying(255),
    role character varying(255),
    email character varying(255),
    encrypted_password character varying(255),
    email_confirmed_at timestamp with time zone,
    invited_at timestamp with time zone,
    confirmation_token character varying(255),
    confirmation_sent_at timestamp with time zone,
    recovery_token character varying(255),
    recovery_sent_at timestamp with time zone,
    email_change_token_new character varying(255),
    email_change character varying(255),
    email_change_sent_at timestamp with time zone,
    last_sign_in_at timestamp with time zone,
    raw_app_meta_data jsonb,
    raw_user_meta_data jsonb,
    is_super_admin boolean,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    phone text DEFAULT NULL::character varying,
    phone_confirmed_at timestamp with time zone,
    phone_change text DEFAULT ''::character varying,
    phone_change_token character varying(255) DEFAULT ''::character varying,
    phone_change_sent_at timestamp with time zone,
    confirmed_at timestamp with time zone GENERATED ALWAYS AS (LEAST(email_confirmed_at, phone_confirmed_at)) STORED,
    email_change_token_current character varying(255) DEFAULT ''::character varying,
    email_change_confirm_status smallint DEFAULT 0,
    banned_until timestamp with time zone,
    reauthentication_token character varying(255) DEFAULT ''::character varying,
    reauthentication_sent_at timestamp with time zone,
    is_sso_user boolean DEFAULT false NOT NULL,
    deleted_at timestamp with time zone,
    is_anonymous boolean DEFAULT false NOT NULL,
    CONSTRAINT users_email_change_confirm_status_check CHECK (((email_change_confirm_status >= 0) AND (email_change_confirm_status <= 2)))
);


--
-- Name: TABLE users; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON TABLE auth.users IS 'Auth: Stores user login data within a secure schema.';


--
-- Name: COLUMN users.is_sso_user; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON COLUMN auth.users.is_sso_user IS 'Auth: Set this column to true when the account comes from SSO. These accounts can have duplicate emails.';


--
-- Name: webauthn_challenges; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.webauthn_challenges (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid,
    challenge_type text NOT NULL,
    session_data jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    CONSTRAINT webauthn_challenges_challenge_type_check CHECK ((challenge_type = ANY (ARRAY['signup'::text, 'registration'::text, 'authentication'::text])))
);


--
-- Name: webauthn_credentials; Type: TABLE; Schema: auth; Owner: -
--

CREATE TABLE auth.webauthn_credentials (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    credential_id bytea NOT NULL,
    public_key bytea NOT NULL,
    attestation_type text DEFAULT ''::text NOT NULL,
    aaguid uuid,
    sign_count bigint DEFAULT 0 NOT NULL,
    transports jsonb DEFAULT '[]'::jsonb NOT NULL,
    backup_eligible boolean DEFAULT false NOT NULL,
    backed_up boolean DEFAULT false NOT NULL,
    friendly_name text DEFAULT ''::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    last_used_at timestamp with time zone
);


--
-- Name: app_users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.app_users (
    id uuid NOT NULL,
    full_name text,
    role text DEFAULT 'staff'::text NOT NULL,
    phone text,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT app_users_role_check CHECK ((role = ANY (ARRAY['admin'::text, 'sales'::text, 'manager'::text, 'staff'::text])))
);


--
-- Name: brochures; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.brochures (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    model text NOT NULL,
    file_name text NOT NULL,
    storage_path text NOT NULL,
    public_url text,
    version text,
    is_active boolean DEFAULT true NOT NULL,
    uploaded_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: campaign_recipients; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.campaign_recipients (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    campaign_id uuid NOT NULL,
    phone text NOT NULL,
    customer_name text,
    variables jsonb,
    send_status text DEFAULT 'pending'::text NOT NULL,
    error_message text,
    sent_at timestamp with time zone,
    delivered_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: campaign_templates; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.campaign_templates (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    template_name text NOT NULL,
    language_code text NOT NULL,
    category text NOT NULL,
    header_type text,
    body_example text,
    buttons jsonb,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: campaigns; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.campaigns (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL,
    template_id uuid,
    status text DEFAULT 'draft'::text NOT NULL,
    recipient_source text NOT NULL,
    payload jsonb,
    created_by uuid,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    sent_at timestamp with time zone,
    CONSTRAINT campaigns_status_check CHECK ((status = ANY (ARRAY['draft'::text, 'sending'::text, 'sent'::text, 'failed'::text])))
);


--
-- Name: conversations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.conversations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    phone text NOT NULL,
    lead_id uuid,
    current_state text DEFAULT 'new'::text NOT NULL,
    current_step text,
    last_message_at timestamp with time zone,
    is_open boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    campaign_id uuid
);


--
-- Name: leads; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.leads (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    phone text NOT NULL,
    customer_name text,
    interested_model text,
    fuel_type text,
    transmission text,
    exchange_required boolean,
    lead_status text DEFAULT 'new'::text NOT NULL,
    assigned_to uuid,
    source text DEFAULT 'whatsapp'::text NOT NULL,
    city text,
    notes text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: messages; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.messages (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    conversation_id uuid NOT NULL,
    phone text NOT NULL,
    direction text NOT NULL,
    message_type text DEFAULT 'text'::text NOT NULL,
    content text,
    raw_payload jsonb,
    whatsapp_message_id text,
    status text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT messages_direction_check CHECK ((direction = ANY (ARRAY['inbound'::text, 'outbound'::text])))
);


--
-- Name: pricing_rules; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pricing_rules (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    model text,
    variant_id uuid,
    rule_type text NOT NULL,
    rule_name text NOT NULL,
    value_type text NOT NULL,
    value numeric(12,2) NOT NULL,
    is_stackable boolean DEFAULT false NOT NULL,
    conditions jsonb,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT pricing_rules_check CHECK (((model IS NOT NULL) OR (variant_id IS NOT NULL))),
    CONSTRAINT pricing_rules_value_check CHECK ((value >= (0)::numeric)),
    CONSTRAINT pricing_rules_value_type_check CHECK ((value_type = ANY (ARRAY['fixed'::text, 'percent'::text])))
);


--
-- Name: variants; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.variants (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    model text NOT NULL,
    variant_name text NOT NULL,
    fuel_type text NOT NULL,
    transmission text NOT NULL,
    ex_showroom_price numeric(12,2) NOT NULL,
    brochure_url text,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    insurance numeric(12,2) DEFAULT 0,
    rto_standard numeric(12,2) DEFAULT 0,
    rto_rate numeric(5,4) DEFAULT 0,
    rto_bh numeric(12,2) DEFAULT 0,
    rto_scrap numeric(12,2) DEFAULT 0,
    scheme_consumer numeric(12,2) DEFAULT 0,
    scheme_exchange_scrap numeric(12,2) DEFAULT 0,
    scheme_additional_scrap numeric(12,2) DEFAULT 0,
    scheme_corporate numeric(12,2) DEFAULT 0,
    scheme_intervention numeric(12,2) DEFAULT 0,
    scheme_solar numeric(12,2) DEFAULT 0,
    scheme_msme numeric(12,2) DEFAULT 0,
    scheme_green_bonus numeric(12,2) DEFAULT 0,
    CONSTRAINT variants_ex_showroom_price_check CHECK ((ex_showroom_price >= (0)::numeric))
);


--
-- Name: messages; Type: TABLE; Schema: realtime; Owner: -
--

CREATE TABLE realtime.messages (
    topic text NOT NULL,
    extension text NOT NULL,
    payload jsonb,
    event text,
    private boolean DEFAULT false,
    updated_at timestamp without time zone DEFAULT now() NOT NULL,
    inserted_at timestamp without time zone DEFAULT now() NOT NULL,
    id uuid DEFAULT gen_random_uuid() NOT NULL
)
PARTITION BY RANGE (inserted_at);


--
-- Name: schema_migrations; Type: TABLE; Schema: realtime; Owner: -
--

CREATE TABLE realtime.schema_migrations (
    version bigint NOT NULL,
    inserted_at timestamp(0) without time zone
);


--
-- Name: subscription; Type: TABLE; Schema: realtime; Owner: -
--

CREATE TABLE realtime.subscription (
    id bigint NOT NULL,
    subscription_id uuid NOT NULL,
    entity regclass NOT NULL,
    filters realtime.user_defined_filter[] DEFAULT '{}'::realtime.user_defined_filter[] NOT NULL,
    claims jsonb NOT NULL,
    claims_role regrole GENERATED ALWAYS AS (realtime.to_regrole((claims ->> 'role'::text))) STORED NOT NULL,
    created_at timestamp without time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    action_filter text DEFAULT '*'::text,
    CONSTRAINT subscription_action_filter_check CHECK ((action_filter = ANY (ARRAY['*'::text, 'INSERT'::text, 'UPDATE'::text, 'DELETE'::text])))
);


--
-- Name: subscription_id_seq; Type: SEQUENCE; Schema: realtime; Owner: -
--

ALTER TABLE realtime.subscription ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME realtime.subscription_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- Name: buckets; Type: TABLE; Schema: storage; Owner: -
--

CREATE TABLE storage.buckets (
    id text NOT NULL,
    name text NOT NULL,
    owner uuid,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    public boolean DEFAULT false,
    avif_autodetection boolean DEFAULT false,
    file_size_limit bigint,
    allowed_mime_types text[],
    owner_id text,
    type storage.buckettype DEFAULT 'STANDARD'::storage.buckettype NOT NULL
);


--
-- Name: COLUMN buckets.owner; Type: COMMENT; Schema: storage; Owner: -
--

COMMENT ON COLUMN storage.buckets.owner IS 'Field is deprecated, use owner_id instead';


--
-- Name: buckets_analytics; Type: TABLE; Schema: storage; Owner: -
--

CREATE TABLE storage.buckets_analytics (
    name text NOT NULL,
    type storage.buckettype DEFAULT 'ANALYTICS'::storage.buckettype NOT NULL,
    format text DEFAULT 'ICEBERG'::text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    deleted_at timestamp with time zone
);


--
-- Name: buckets_vectors; Type: TABLE; Schema: storage; Owner: -
--

CREATE TABLE storage.buckets_vectors (
    id text NOT NULL,
    type storage.buckettype DEFAULT 'VECTOR'::storage.buckettype NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: migrations; Type: TABLE; Schema: storage; Owner: -
--

CREATE TABLE storage.migrations (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    hash character varying(40) NOT NULL,
    executed_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: objects; Type: TABLE; Schema: storage; Owner: -
--

CREATE TABLE storage.objects (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    bucket_id text,
    name text,
    owner uuid,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    last_accessed_at timestamp with time zone DEFAULT now(),
    metadata jsonb,
    path_tokens text[] GENERATED ALWAYS AS (string_to_array(name, '/'::text)) STORED,
    version text,
    owner_id text,
    user_metadata jsonb
);


--
-- Name: COLUMN objects.owner; Type: COMMENT; Schema: storage; Owner: -
--

COMMENT ON COLUMN storage.objects.owner IS 'Field is deprecated, use owner_id instead';


--
-- Name: s3_multipart_uploads; Type: TABLE; Schema: storage; Owner: -
--

CREATE TABLE storage.s3_multipart_uploads (
    id text NOT NULL,
    in_progress_size bigint DEFAULT 0 NOT NULL,
    upload_signature text NOT NULL,
    bucket_id text NOT NULL,
    key text NOT NULL COLLATE pg_catalog."C",
    version text NOT NULL,
    owner_id text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    user_metadata jsonb
);


--
-- Name: s3_multipart_uploads_parts; Type: TABLE; Schema: storage; Owner: -
--

CREATE TABLE storage.s3_multipart_uploads_parts (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    upload_id text NOT NULL,
    size bigint DEFAULT 0 NOT NULL,
    part_number integer NOT NULL,
    bucket_id text NOT NULL,
    key text NOT NULL COLLATE pg_catalog."C",
    etag text NOT NULL,
    owner_id text,
    version text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: vector_indexes; Type: TABLE; Schema: storage; Owner: -
--

CREATE TABLE storage.vector_indexes (
    id text DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL COLLATE pg_catalog."C",
    bucket_id text NOT NULL,
    data_type text NOT NULL,
    dimension integer NOT NULL,
    distance_metric text NOT NULL,
    metadata_configuration jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: schema_migrations; Type: TABLE; Schema: supabase_migrations; Owner: -
--

CREATE TABLE supabase_migrations.schema_migrations (
    version text NOT NULL,
    statements text[],
    name text
);


--
-- Name: refresh_tokens id; Type: DEFAULT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.refresh_tokens ALTER COLUMN id SET DEFAULT nextval('auth.refresh_tokens_id_seq'::regclass);


--
-- Data for Name: audit_log_entries; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.audit_log_entries (instance_id, id, payload, created_at, ip_address) FROM stdin;
\.


--
-- Data for Name: custom_oauth_providers; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.custom_oauth_providers (id, provider_type, identifier, name, client_id, client_secret, acceptable_client_ids, scopes, pkce_enabled, attribute_mapping, authorization_params, enabled, email_optional, issuer, discovery_url, skip_nonce_check, cached_discovery, discovery_cached_at, authorization_url, token_url, userinfo_url, jwks_uri, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: flow_state; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.flow_state (id, user_id, auth_code, code_challenge_method, code_challenge, provider_type, provider_access_token, provider_refresh_token, created_at, updated_at, authentication_method, auth_code_issued_at, invite_token, referrer, oauth_client_state_id, linking_target_id, email_optional) FROM stdin;
\.


--
-- Data for Name: identities; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.identities (provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at, id) FROM stdin;
\.


--
-- Data for Name: instances; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.instances (id, uuid, raw_base_config, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: mfa_amr_claims; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.mfa_amr_claims (session_id, created_at, updated_at, authentication_method, id) FROM stdin;
\.


--
-- Data for Name: mfa_challenges; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.mfa_challenges (id, factor_id, created_at, verified_at, ip_address, otp_code, web_authn_session_data) FROM stdin;
\.


--
-- Data for Name: mfa_factors; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.mfa_factors (id, user_id, friendly_name, factor_type, status, created_at, updated_at, secret, phone, last_challenged_at, web_authn_credential, web_authn_aaguid, last_webauthn_challenge_data) FROM stdin;
\.


--
-- Data for Name: oauth_authorizations; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.oauth_authorizations (id, authorization_id, client_id, user_id, redirect_uri, scope, state, resource, code_challenge, code_challenge_method, response_type, status, authorization_code, created_at, expires_at, approved_at, nonce) FROM stdin;
\.


--
-- Data for Name: oauth_client_states; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.oauth_client_states (id, provider_type, code_verifier, created_at) FROM stdin;
\.


--
-- Data for Name: oauth_clients; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.oauth_clients (id, client_secret_hash, registration_type, redirect_uris, grant_types, client_name, client_uri, logo_uri, created_at, updated_at, deleted_at, client_type, token_endpoint_auth_method) FROM stdin;
\.


--
-- Data for Name: oauth_consents; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.oauth_consents (id, user_id, client_id, scopes, granted_at, revoked_at) FROM stdin;
\.


--
-- Data for Name: one_time_tokens; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.one_time_tokens (id, user_id, token_type, token_hash, relates_to, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: refresh_tokens; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.refresh_tokens (instance_id, id, token, user_id, revoked, created_at, updated_at, parent, session_id) FROM stdin;
\.


--
-- Data for Name: saml_providers; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.saml_providers (id, sso_provider_id, entity_id, metadata_xml, metadata_url, attribute_mapping, created_at, updated_at, name_id_format) FROM stdin;
\.


--
-- Data for Name: saml_relay_states; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.saml_relay_states (id, sso_provider_id, request_id, for_email, redirect_to, created_at, updated_at, flow_state_id) FROM stdin;
\.


--
-- Data for Name: schema_migrations; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.schema_migrations (version) FROM stdin;
20171026211738
20171026211808
20171026211834
20180103212743
20180108183307
20180119214651
20180125194653
00
20210710035447
20210722035447
20210730183235
20210909172000
20210927181326
20211122151130
20211124214934
20211202183645
20220114185221
20220114185340
20220224000811
20220323170000
20220429102000
20220531120530
20220614074223
20220811173540
20221003041349
20221003041400
20221011041400
20221020193600
20221021073300
20221021082433
20221027105023
20221114143122
20221114143410
20221125140132
20221208132122
20221215195500
20221215195800
20221215195900
20230116124310
20230116124412
20230131181311
20230322519590
20230402418590
20230411005111
20230508135423
20230523124323
20230818113222
20230914180801
20231027141322
20231114161723
20231117164230
20240115144230
20240214120130
20240306115329
20240314092811
20240427152123
20240612123726
20240729123726
20240802193726
20240806073726
20241009103726
20250717082212
20250731150234
20250804100000
20250901200500
20250903112500
20250904133000
20250925093508
20251007112900
20251104100000
20251111201300
20251201000000
20260115000000
20260121000000
20260219120000
20260302000000
\.


--
-- Data for Name: sessions; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.sessions (id, user_id, created_at, updated_at, factor_id, aal, not_after, refreshed_at, user_agent, ip, tag, oauth_client_id, refresh_token_hmac_key, refresh_token_counter, scopes) FROM stdin;
\.


--
-- Data for Name: sso_domains; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.sso_domains (id, sso_provider_id, domain, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: sso_providers; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.sso_providers (id, resource_id, created_at, updated_at, disabled) FROM stdin;
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.users (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at, invited_at, confirmation_token, confirmation_sent_at, recovery_token, recovery_sent_at, email_change_token_new, email_change, email_change_sent_at, last_sign_in_at, raw_app_meta_data, raw_user_meta_data, is_super_admin, created_at, updated_at, phone, phone_confirmed_at, phone_change, phone_change_token, phone_change_sent_at, email_change_token_current, email_change_confirm_status, banned_until, reauthentication_token, reauthentication_sent_at, is_sso_user, deleted_at, is_anonymous) FROM stdin;
\.


--
-- Data for Name: webauthn_challenges; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.webauthn_challenges (id, user_id, challenge_type, session_data, created_at, expires_at) FROM stdin;
\.


--
-- Data for Name: webauthn_credentials; Type: TABLE DATA; Schema: auth; Owner: -
--

COPY auth.webauthn_credentials (id, user_id, credential_id, public_key, attestation_type, aaguid, sign_count, transports, backup_eligible, backed_up, friendly_name, created_at, updated_at, last_used_at) FROM stdin;
\.


--
-- Data for Name: app_users; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.app_users (id, full_name, role, phone, is_active, created_at) FROM stdin;
\.


--
-- Data for Name: brochures; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.brochures (id, model, file_name, storage_path, public_url, version, is_active, uploaded_by, created_at) FROM stdin;
\.


--
-- Data for Name: campaign_recipients; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.campaign_recipients (id, campaign_id, phone, customer_name, variables, send_status, error_message, sent_at, delivered_at, created_at) FROM stdin;
\.


--
-- Data for Name: campaign_templates; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.campaign_templates (id, template_name, language_code, category, header_type, body_example, buttons, is_active, created_at) FROM stdin;
08331df9-53f1-4290-846b-09d4a1f392ab	new_launch_followup	en	marketing	text	Hello {{1}}, check out our latest offers on {{2}}. Reply to get variant and on-road pricing details.	[{"text": "Show variants", "type": "quick_reply"}, {"text": "Get pricing", "type": "quick_reply"}]	t	2026-03-21 06:27:57.991165+00
\.


--
-- Data for Name: campaigns; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.campaigns (id, name, template_id, status, recipient_source, payload, created_by, created_at, sent_at) FROM stdin;
\.


--
-- Data for Name: conversations; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.conversations (id, phone, lead_id, current_state, current_step, last_message_at, is_open, created_at, updated_at, campaign_id) FROM stdin;
7ce6e858-f84d-42d2-bdd8-eaa4fd53d162	919876543210	badaa9be-362e-4470-947e-5462b6fdd47a	lead_capture	ask_name	2024-03-21 13:24:00+00	t	2026-03-21 07:28:15.834716+00	2026-03-21 08:18:27.445269+00	\N
f51d1fd9-3ac2-4095-9cf3-a64f477d142b	16315551181	63b981d1-d988-42d8-ab6a-24b9c99fd327	lead_capture	ask_name	2017-09-08 20:36:28+00	t	2026-03-21 10:27:22.549159+00	2026-03-21 10:27:26.138158+00	\N
ec8b34ad-3324-44ea-8512-2972e81cc3f6	917424900000	9d0b71cf-0caf-4515-b5c0-215c34dfc8be	qualified	complete	2026-03-21 10:31:55+00	t	2026-03-21 07:39:33.623212+00	2026-03-21 10:32:00.314357+00	\N
193ab0dc-7592-45b9-8b3f-92e5042d4770	918963000000	34c2c0b8-2214-46a5-8855-441dc56c1725	lead_capture	ask_fuel	2026-03-20 07:45:50+00	t	2026-03-21 07:59:03.073559+00	2026-03-21 17:18:21.498603+00	\N
024ae476-57c7-4b87-8f44-6a8d18e1838d	918422939422	1a7cc974-71e5-4127-9099-87844e1d3f22	lead_capture	ask_name	2026-03-22 10:41:37+00	t	2026-03-21 08:58:15.767536+00	2026-03-22 10:41:42.904373+00	\N
\.


--
-- Data for Name: leads; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.leads (id, phone, customer_name, interested_model, fuel_type, transmission, exchange_required, lead_status, assigned_to, source, city, notes, created_at, updated_at) FROM stdin;
badaa9be-362e-4470-947e-5462b6fdd47a	919876543210	\N	\N	\N	\N	\N	new	\N	whatsapp	\N	\N	2026-03-21 07:28:15.39653+00	2026-03-21 07:28:15.39653+00
9d0b71cf-0caf-4515-b5c0-215c34dfc8be	917424900000	Rahul	Hyundai Creta	petrol	automatic	t	qualified	\N	whatsapp	\N	\N	2026-03-21 07:39:32.704483+00	2026-03-21 07:42:42.608783+00
1a7cc974-71e5-4127-9099-87844e1d3f22	918422939422	\N	\N	\N	\N	\N	new	\N	whatsapp	\N	\N	2026-03-21 08:58:15.263665+00	2026-03-21 08:58:15.263665+00
63b981d1-d988-42d8-ab6a-24b9c99fd327	16315551181	\N	\N	\N	\N	\N	new	\N	whatsapp	\N	\N	2026-03-21 10:27:22.03108+00	2026-03-21 10:27:22.03108+00
34c2c0b8-2214-46a5-8855-441dc56c1725	918963000000	Hi I Need Price For Tata Neon	Nexon	\N	\N	\N	new	\N	whatsapp	\N	\N	2026-03-21 07:59:02.022496+00	2026-03-21 17:18:21.24255+00
\.


--
-- Data for Name: messages; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.messages (id, conversation_id, phone, direction, message_type, content, raw_payload, whatsapp_message_id, status, created_at) FROM stdin;
8da9cb5e-01bf-41f2-8449-c196602013ee	7ce6e858-f84d-42d2-bdd8-eaa4fd53d162	919876543210	inbound	text	Hi, I want Nexon price	{"id": "wamid.prod123", "from": "919876543210", "text": {"body": "Hi, I want Nexon price"}, "type": "text", "timestamp": "1711027440"}	wamid.prod123	\N	2024-03-21 13:24:00+00
8c8a9c2b-40a3-46a7-aa71-b3b7efa02d27	ec8b34ad-3324-44ea-8512-2972e81cc3f6	917424900000	inbound	text	hi	{"id": "wamid.HBgMOTE3NDI0OTAwMDAwFQIAEhgUM0I5MUEzNTdGMEQ1NjNFNDNFQzMA", "from": "917424900000", "text": {"body": "hi"}, "type": "text", "timestamp": "1774078769"}	wamid.HBgMOTE3NDI0OTAwMDAwFQIAEhgUM0I5MUEzNTdGMEQ1NjNFNDNFQzMA	\N	2026-03-21 07:39:29+00
be834055-4352-4fd5-acfa-3c2fa99c0e04	ec8b34ad-3324-44ea-8512-2972e81cc3f6	917424900000	outbound	text	Welcome to Techwheels. May I have your name?	{"source": "lead_capture_state_machine", "next_step": "ask_name", "next_state": "lead_capture", "conversation_id": "ec8b34ad-3324-44ea-8512-2972e81cc3f6"}	\N	queued	2026-03-21 07:39:35.436+00
e50f32bb-ddf1-498c-b16d-76db47ef78a0	ec8b34ad-3324-44ea-8512-2972e81cc3f6	917424900000	inbound	text	Rahul	{"id": "wamid.HBgMOTE3NDI0OTAwMDAwFQIAEhgUM0JCNTQ2MTQ3Rjg5QjMzRkI4MDEA", "from": "917424900000", "text": {"body": "Rahul"}, "type": "text", "timestamp": "1774078818"}	wamid.HBgMOTE3NDI0OTAwMDAwFQIAEhgUM0JCNTQ2MTQ3Rjg5QjMzRkI4MDEA	\N	2026-03-21 07:40:18+00
ccdde51c-3873-467f-9250-4cc9f3015a1e	ec8b34ad-3324-44ea-8512-2972e81cc3f6	917424900000	outbound	text	Thanks Rahul. Which model are you interested in? Available options: Hyundai Creta, Kia Seltos.	{"source": "lead_capture_state_machine", "next_step": "ask_model", "next_state": "lead_capture", "conversation_id": "ec8b34ad-3324-44ea-8512-2972e81cc3f6"}	\N	queued	2026-03-21 07:40:23.419+00
2ceb56f5-dac4-4e23-98f3-2ee0600cb7b2	ec8b34ad-3324-44ea-8512-2972e81cc3f6	917424900000	inbound	text	Creta	{"id": "wamid.HBgMOTE3NDI0OTAwMDAwFQIAEhgUM0I4QzlCNzM3NTUzOEY2OUM4ODUA", "from": "917424900000", "text": {"body": "Creta"}, "type": "text", "timestamp": "1774078842"}	wamid.HBgMOTE3NDI0OTAwMDAwFQIAEhgUM0I4QzlCNzM3NTUzOEY2OUM4ODUA	\N	2026-03-21 07:40:42+00
8e579b11-193d-4beb-8582-24672169821e	ec8b34ad-3324-44ea-8512-2972e81cc3f6	917424900000	outbound	text	Please choose one of these models: Hyundai Creta, Kia Seltos.	{"source": "lead_capture_state_machine", "next_step": "ask_model", "next_state": "lead_capture", "conversation_id": "ec8b34ad-3324-44ea-8512-2972e81cc3f6"}	\N	queued	2026-03-21 07:40:47.399+00
97bb2e81-879f-4b16-83b0-3566439923d0	ec8b34ad-3324-44ea-8512-2972e81cc3f6	917424900000	inbound	text	Hyundai Creta	{"id": "wamid.HBgMOTE3NDI0OTAwMDAwFQIAEhgUM0JCQUE4MTg2QkRFM0U0QkE2RDYA", "from": "917424900000", "text": {"body": "Hyundai Creta"}, "type": "text", "timestamp": "1774078883"}	wamid.HBgMOTE3NDI0OTAwMDAwFQIAEhgUM0JCQUE4MTg2QkRFM0U0QkE2RDYA	\N	2026-03-21 07:41:23+00
1b16774e-d7aa-4311-ab51-ef80f07ac058	ec8b34ad-3324-44ea-8512-2972e81cc3f6	917424900000	outbound	text	Got it. Which fuel type do you prefer: petrol, diesel, cng, or ev?	{"source": "lead_capture_state_machine", "next_step": "ask_fuel", "next_state": "lead_capture", "conversation_id": "ec8b34ad-3324-44ea-8512-2972e81cc3f6"}	\N	queued	2026-03-21 07:41:27.778+00
1ca23555-6e67-4385-ba36-46f41acc7ce8	ec8b34ad-3324-44ea-8512-2972e81cc3f6	917424900000	inbound	text	petrol	{"id": "wamid.HBgMOTE3NDI0OTAwMDAwFQIAEhgUM0JEOTNBQjk2OTc0QTBENDJDMzEA", "from": "917424900000", "text": {"body": "petrol"}, "type": "text", "timestamp": "1774078896"}	wamid.HBgMOTE3NDI0OTAwMDAwFQIAEhgUM0JEOTNBQjk2OTc0QTBENDJDMzEA	\N	2026-03-21 07:41:36+00
8bf34fae-ba05-4099-8872-5521eef17d8b	ec8b34ad-3324-44ea-8512-2972e81cc3f6	917424900000	outbound	text	Thanks. Which transmission would you like: manual or automatic?	{"source": "lead_capture_state_machine", "next_step": "ask_transmission", "next_state": "lead_capture", "conversation_id": "ec8b34ad-3324-44ea-8512-2972e81cc3f6"}	\N	queued	2026-03-21 07:41:39.845+00
8becf8c4-aeb0-4da1-a3ec-3fa71c970475	ec8b34ad-3324-44ea-8512-2972e81cc3f6	917424900000	inbound	text	automatic	{"id": "wamid.HBgMOTE3NDI0OTAwMDAwFQIAEhgUM0JGNUFENTAxMzhDRTRFMDg3NjIA", "from": "917424900000", "text": {"body": "automatic"}, "type": "text", "timestamp": "1774078928"}	wamid.HBgMOTE3NDI0OTAwMDAwFQIAEhgUM0JGNUFENTAxMzhDRTRFMDg3NjIA	\N	2026-03-21 07:42:08+00
b2be05c0-b96d-4fce-b525-97de8ef7eb02	ec8b34ad-3324-44ea-8512-2972e81cc3f6	917424900000	outbound	text	Do you have a car for exchange? Please reply yes or no.	{"source": "lead_capture_state_machine", "next_step": "ask_exchange", "next_state": "lead_capture", "conversation_id": "ec8b34ad-3324-44ea-8512-2972e81cc3f6"}	\N	queued	2026-03-21 07:42:12.291+00
14912dd1-059e-45fd-9eac-1d4efb768d9f	ec8b34ad-3324-44ea-8512-2972e81cc3f6	917424900000	inbound	text	yes	{"id": "wamid.HBgMOTE3NDI0OTAwMDAwFQIAEhgUM0I0RUQ4RjBFMTEzQ0YyRTI1QzYA", "from": "917424900000", "text": {"body": "yes"}, "type": "text", "timestamp": "1774078957"}	wamid.HBgMOTE3NDI0OTAwMDAwFQIAEhgUM0I0RUQ4RjBFMTEzQ0YyRTI1QzYA	\N	2026-03-21 07:42:37+00
003567ab-8a62-457d-86e6-ff21590871aa	ec8b34ad-3324-44ea-8512-2972e81cc3f6	917424900000	outbound	text	Perfect. I have your details now. I can help you next with matching variants and on-road pricing.	{"source": "lead_capture_state_machine", "next_step": "complete", "next_state": "qualified", "conversation_id": "ec8b34ad-3324-44ea-8512-2972e81cc3f6"}	\N	queued	2026-03-21 07:42:43.031+00
292eaa92-2513-4129-8828-c70fe84156c6	ec8b34ad-3324-44ea-8512-2972e81cc3f6	917424900000	inbound	text	Hello	{"id": "wamid.HBgMOTE3NDI0OTAwMDAwFQIAEhgUM0JGRUI2Qjc5NjA4QkM5ODRGMzIA", "from": "917424900000", "text": {"body": "Hello"}, "type": "text", "timestamp": "1774079009"}	wamid.HBgMOTE3NDI0OTAwMDAwFQIAEhgUM0JGRUI2Qjc5NjA4QkM5ODRGMzIA	\N	2026-03-21 07:43:29+00
bdae45ee-69c8-47bf-b275-9f6adec7a893	ec8b34ad-3324-44ea-8512-2972e81cc3f6	917424900000	outbound	text	Thanks, I have your details. I can now help you with variants and pricing.	{"source": "lead_capture_state_machine", "next_step": "complete", "next_state": "qualified", "conversation_id": "ec8b34ad-3324-44ea-8512-2972e81cc3f6"}	\N	queued	2026-03-21 07:43:33.15+00
e9d7c3e6-ee10-4f6a-bdc0-8c682abc1648	ec8b34ad-3324-44ea-8512-2972e81cc3f6	917424900000	inbound	text	Yes tell me	{"id": "wamid.HBgMOTE3NDI0OTAwMDAwFQIAEhgUM0FFOTY4NTNGODY2QkI4OUMzODkA", "from": "917424900000", "text": {"body": "Yes tell me"}, "type": "text", "timestamp": "1774011197"}	wamid.HBgMOTE3NDI0OTAwMDAwFQIAEhgUM0FFOTY4NTNGODY2QkI4OUMzODkA	\N	2026-03-20 12:53:17+00
941679ff-11d3-448d-bcc5-92496e3d487f	ec8b34ad-3324-44ea-8512-2972e81cc3f6	917424900000	outbound	text	Thanks, I have your details. I can now help you with variants and pricing.	{"source": "lead_capture_state_machine", "next_step": "complete", "next_state": "qualified", "conversation_id": "ec8b34ad-3324-44ea-8512-2972e81cc3f6"}	\N	queued	2026-03-21 07:48:42.107+00
3d42d91f-504a-49ae-a538-d66516fb6431	ec8b34ad-3324-44ea-8512-2972e81cc3f6	917424900000	inbound	text	hello	{"id": "wamid.HBgMOTE3NDI0OTAwMDAwFQIAEhgUM0I2MkIzNzU4QjY3RDI1NUU2REMA", "from": "917424900000", "text": {"body": "hello"}, "type": "text", "timestamp": "1774079560"}	wamid.HBgMOTE3NDI0OTAwMDAwFQIAEhgUM0I2MkIzNzU4QjY3RDI1NUU2REMA	\N	2026-03-21 07:52:40+00
847b522b-5ef5-4333-a7b4-ec75edecc29e	ec8b34ad-3324-44ea-8512-2972e81cc3f6	917424900000	outbound	text	Thanks, I have your details. I can now help you with variants and pricing.	{"source": "lead_capture_state_machine", "next_step": "complete", "next_state": "qualified", "conversation_id": "ec8b34ad-3324-44ea-8512-2972e81cc3f6"}	\N	queued	2026-03-21 07:52:43.252+00
9b2e95ee-8030-46f5-a82a-a1347dcc3fba	193ab0dc-7592-45b9-8b3f-92e5042d4770	918963000000	inbound	text	Hi need price for tata nexon	{"id": "wamid.HBgMOTE4OTYzMDAwMDAwFQIAEhgUM0EyRkU0MzQyRjNFQjZFRkIwRTQA", "from": "918963000000", "text": {"body": "Hi need price for tata nexon"}, "type": "text", "timestamp": "1773989501"}	wamid.HBgMOTE4OTYzMDAwMDAwFQIAEhgUM0EyRkU0MzQyRjNFQjZFRkIwRTQA	\N	2026-03-20 06:51:41+00
4f6c34c5-0141-427d-be13-caf304bcd063	193ab0dc-7592-45b9-8b3f-92e5042d4770	918963000000	outbound	text	Welcome to Techwheels. May I have your name?	{"source": "lead_capture_state_machine", "next_step": "ask_name", "next_state": "lead_capture", "conversation_id": "193ab0dc-7592-45b9-8b3f-92e5042d4770"}	\N	queued	2026-03-21 07:59:05.44+00
695c6c2a-f164-433f-ad72-c03444c39a86	7ce6e858-f84d-42d2-bdd8-eaa4fd53d162	919876543210	inbound	text	Hi	{"id": "msg-1", "from": "919876543210", "text": {"body": "Hi"}, "type": "text", "timestamp": "1711027440"}	msg-1	\N	2024-03-21 13:24:00+00
6709c442-4050-4938-9e6f-d8196d75335e	7ce6e858-f84d-42d2-bdd8-eaa4fd53d162	919876543210	outbound	text	Welcome to Techwheels. May I have your name?	{"route": "lead_capture", "source": "message_router", "conversation_id": "7ce6e858-f84d-42d2-bdd8-eaa4fd53d162", "detected_intent": "fallback"}	\N	queued	2026-03-21 08:18:27.548+00
9768ae90-dbf2-44dd-8204-d2b9c21edd14	ec8b34ad-3324-44ea-8512-2972e81cc3f6	917424900000	inbound	text	What is the on road price?	{"id": "wamid.HBgMOTE3NDI0OTAwMDAwFQIAEhgUM0I1ODAwQUY1Mzk2RTlFRjM3REUA", "from": "917424900000", "text": {"body": "What is the on road price?"}, "type": "text", "timestamp": "1774081137"}	wamid.HBgMOTE3NDI0OTAwMDAwFQIAEhgUM0I1ODAwQUY1Mzk2RTlFRjM3REUA	\N	2026-03-21 08:18:57+00
b86126c5-e539-4ab2-b2d1-88b67f29702f	ec8b34ad-3324-44ea-8512-2972e81cc3f6	917424900000	outbound	text	Here is the on-road estimate for Hyundai Creta SX:\nEx-showroom: Rs. 15,75,000\nRTO: Rs. 0\nInsurance: Rs. 0\nHandling: Rs. 0\nAccessories: Rs. 0\nDiscounts: Rs. 25,000\nFinal on-road price: Rs. 15,50,000\nApplied offers: Creta Exchange Bonus	{"route": "pricing", "source": "message_router", "conversation_id": "ec8b34ad-3324-44ea-8512-2972e81cc3f6", "detected_intent": "pricing"}	\N	queued	2026-03-21 08:19:04.161+00
66ba55bb-4fb8-4944-b739-813180fb6668	ec8b34ad-3324-44ea-8512-2972e81cc3f6	917424900000	inbound	text	Price for Creta SX	{"id": "wamid.HBgMOTE3NDI0OTAwMDAwFQIAEhgUM0I0NUY0NzIxMTY5OTE2OEIzNEYA", "from": "917424900000", "text": {"body": "Price for Creta SX"}, "type": "text", "timestamp": "1774081174"}	wamid.HBgMOTE3NDI0OTAwMDAwFQIAEhgUM0I0NUY0NzIxMTY5OTE2OEIzNEYA	\N	2026-03-21 08:19:34+00
d13f3444-6b04-4c6c-9c65-621ca4a31e24	ec8b34ad-3324-44ea-8512-2972e81cc3f6	917424900000	outbound	text	Here is the on-road estimate for Hyundai Creta SX:\nEx-showroom: Rs. 15,75,000\nRTO: Rs. 0\nInsurance: Rs. 0\nHandling: Rs. 0\nAccessories: Rs. 0\nDiscounts: Rs. 25,000\nFinal on-road price: Rs. 15,50,000\nApplied offers: Creta Exchange Bonus	{"route": "pricing", "source": "message_router", "conversation_id": "ec8b34ad-3324-44ea-8512-2972e81cc3f6", "detected_intent": "pricing"}	\N	queued	2026-03-21 08:19:39.092+00
d6a027d5-b4c0-48fa-971e-a5ec06ec1284	ec8b34ad-3324-44ea-8512-2972e81cc3f6	917424900000	inbound	text	Does it have sunroof?	{"id": "wamid.HBgMOTE3NDI0OTAwMDAwFQIAEhgUM0JEQzczN0Q3N0Q3Q0IxMDA0RjYA", "from": "917424900000", "text": {"body": "Does it have sunroof?"}, "type": "text", "timestamp": "1774081213"}	wamid.HBgMOTE3NDI0OTAwMDAwFQIAEhgUM0JEQzczN0Q3N0Q3Q0IxMDA0RjYA	\N	2026-03-21 08:20:13+00
b077242d-4e6e-48e5-a052-6fb7f491d88b	ec8b34ad-3324-44ea-8512-2972e81cc3f6	917424900000	outbound	text	I’m not fully sure about that from the brochure details I have right now. I can help with available variants, pricing, or connect you with our sales advisor for confirmation.	{"route": "features", "source": "message_router", "conversation_id": "ec8b34ad-3324-44ea-8512-2972e81cc3f6", "detected_intent": "features"}	\N	queued	2026-03-21 08:20:18.666+00
389c5041-c842-4bbc-ba71-ebd9b4347f89	193ab0dc-7592-45b9-8b3f-92e5042d4770	918963000000	inbound	text	Hi I need price for Tata neon	{"id": "wamid.HBgMOTE4OTYzMDAwMDAwFQIAEhgUM0M1RUQxRTNBRkRFMTE1MzlDREUA", "from": "918963000000", "text": {"body": "Hi I need price for Tata neon"}, "type": "text", "timestamp": "1773988960"}	wamid.HBgMOTE4OTYzMDAwMDAwFQIAEhgUM0M1RUQxRTNBRkRFMTE1MzlDREUA	\N	2026-03-20 06:42:40+00
6e18a830-b8b7-4a1b-bceb-267bfc80c079	193ab0dc-7592-45b9-8b3f-92e5042d4770	918963000000	outbound	text	Thanks Hi I Need Price For Tata Neon. Which model are you interested in? Available options: Hyundai Creta, Kia Seltos.	{"route": "lead_capture", "source": "message_router", "conversation_id": "193ab0dc-7592-45b9-8b3f-92e5042d4770", "detected_intent": "pricing"}	\N	queued	2026-03-21 08:39:08.66+00
04ae3072-3b28-4d63-b8af-81bb287597b8	024ae476-57c7-4b87-8f44-6a8d18e1838d	918422939422	inbound	unsupported	\N	{"id": "wamid.HBgMOTE4NDIyOTM5NDIyFQIAEhgSMjlERkZGM0NBODc4RUEyMThEAA==", "from": "918422939422", "type": "unsupported", "errors": [{"code": 131051, "title": "Message type unknown", "message": "Message type unknown", "error_data": {"details": "Message type is currently not supported."}}], "timestamp": "1774083492", "unsupported": {"type": "unknown"}}	wamid.HBgMOTE4NDIyOTM5NDIyFQIAEhgSMjlERkZGM0NBODc4RUEyMThEAA==	\N	2026-03-21 08:58:12+00
64e44140-94dc-457f-8159-b7430a096ba3	024ae476-57c7-4b87-8f44-6a8d18e1838d	918422939422	outbound	text	Welcome to Techwheels. May I have your name?	{"route": "lead_capture", "source": "message_router", "conversation_id": "024ae476-57c7-4b87-8f44-6a8d18e1838d", "detected_intent": "fallback"}	\N	queued	2026-03-21 08:58:18.91+00
090334ef-aaaf-4fc6-9920-4c5f4f7e1071	193ab0dc-7592-45b9-8b3f-92e5042d4770	918963000000	inbound	text	Hello	{"id": "wamid.HBgMOTE4OTYzMDAwMDAwFQIAEhgUM0E4Mzk2NTgzMEEwMDFBRTE5MjAA", "from": "918963000000", "text": {"body": "Hello"}, "type": "text", "timestamp": "1773989931"}	wamid.HBgMOTE4OTYzMDAwMDAwFQIAEhgUM0E4Mzk2NTgzMEEwMDFBRTE5MjAA	\N	2026-03-20 06:58:51+00
cbde1c12-477a-4ddc-a2b7-45035f7f9b17	193ab0dc-7592-45b9-8b3f-92e5042d4770	918963000000	outbound	text	Please choose one of these models: Hyundai Creta, Kia Seltos.	{"route": "lead_capture", "source": "message_router", "conversation_id": "193ab0dc-7592-45b9-8b3f-92e5042d4770", "detected_intent": "fallback"}	\N	queued	2026-03-21 09:01:43.322+00
39d8926c-6904-49a8-9e03-33ad476716f8	193ab0dc-7592-45b9-8b3f-92e5042d4770	918963000000	inbound	text	Hi need price for tata nexon	{"id": "wamid.HBgMOTE4OTYzMDAwMDAwFQIAEhgUM0E0QzJFQzU3OTZDMzA3MEQ5N0MA", "from": "918963000000", "text": {"body": "Hi need price for tata nexon"}, "type": "text", "timestamp": "1773989728"}	wamid.HBgMOTE4OTYzMDAwMDAwFQIAEhgUM0E0QzJFQzU3OTZDMzA3MEQ5N0MA	\N	2026-03-20 06:55:28+00
a645402b-2dce-4ddb-b17d-20a4279b62ed	193ab0dc-7592-45b9-8b3f-92e5042d4770	918963000000	outbound	text	Please choose one of these models: Hyundai Creta, Kia Seltos.	{"route": "lead_capture", "source": "message_router", "conversation_id": "193ab0dc-7592-45b9-8b3f-92e5042d4770", "detected_intent": "pricing"}	\N	queued	2026-03-21 09:05:16.022+00
010c3ccb-581f-47f9-b533-2055c33195d0	193ab0dc-7592-45b9-8b3f-92e5042d4770	918963000000	inbound	text	Hi need price for tata nexon	{"id": "wamid.HBgMOTE4OTYzMDAwMDAwFQIAEhgUM0E0RkI1QjFFN0JENkVEQ0UwNTEA", "from": "918963000000", "text": {"body": "Hi need price for tata nexon"}, "type": "text", "timestamp": "1773989752"}	wamid.HBgMOTE4OTYzMDAwMDAwFQIAEhgUM0E0RkI1QjFFN0JENkVEQ0UwNTEA	\N	2026-03-20 06:55:52+00
ee803a01-8287-4fe3-bd1d-5e49f74512eb	193ab0dc-7592-45b9-8b3f-92e5042d4770	918963000000	outbound	text	Please choose one of these models: Hyundai Creta, Kia Seltos.	{"route": "lead_capture", "source": "message_router", "conversation_id": "193ab0dc-7592-45b9-8b3f-92e5042d4770", "detected_intent": "pricing"}	\N	queued	2026-03-21 09:42:15.634+00
39aa5e28-f455-47b7-9124-c08299c22f15	193ab0dc-7592-45b9-8b3f-92e5042d4770	918963000000	inbound	text	Hi need price for tata nexon	{"id": "wamid.HBgMOTE4OTYzMDAwMDAwFQIAEhgUM0FBQUEzN0IwNTAzNjQ0MDA2MzcA", "from": "918963000000", "text": {"body": "Hi need price for tata nexon"}, "type": "text", "timestamp": "1773989911"}	wamid.HBgMOTE4OTYzMDAwMDAwFQIAEhgUM0FBQUEzN0IwNTAzNjQ0MDA2MzcA	\N	2026-03-20 06:58:31+00
6471043b-0944-42f5-9a6d-bb1ab261c15b	193ab0dc-7592-45b9-8b3f-92e5042d4770	918963000000	outbound	text	Please choose one of these models: Hyundai Creta, Kia Seltos.	{"route": "lead_capture", "source": "message_router", "conversation_id": "193ab0dc-7592-45b9-8b3f-92e5042d4770", "detected_intent": "pricing"}	\N	queued	2026-03-21 10:05:54.544+00
c361c65f-2b3c-41df-bb1f-1d9f5fe5cf74	ec8b34ad-3324-44ea-8512-2972e81cc3f6	917424900000	inbound	text	Hi	{"id": "wamid.HBgMOTE3NDI0OTAwMDAwFQIAEhgUM0E1RkZGOEIxOEIwODc0MEFCQjYA", "from": "917424900000", "text": {"body": "Hi"}, "type": "text", "timestamp": "1774088194"}	wamid.HBgMOTE3NDI0OTAwMDAwFQIAEhgUM0E1RkZGOEIxOEIwODc0MEFCQjYA	\N	2026-03-21 10:16:34+00
d3d19e74-f764-4795-89fd-27b4a6d01c2d	ec8b34ad-3324-44ea-8512-2972e81cc3f6	917424900000	outbound	text	I can help with pricing for Hyundai Creta, features and specifications, or connect you with a human advisor. Just tell me what you need.	{"route": "fallback", "source": "message_router", "conversation_id": "ec8b34ad-3324-44ea-8512-2972e81cc3f6", "detected_intent": "fallback"}	\N	queued	2026-03-21 10:16:39.191+00
3ac8c12a-b061-40bb-9ea2-60a5c75955fa	f51d1fd9-3ac2-4095-9cf3-a64f477d142b	16315551181	inbound	text	this is a text message	{"id": "ABGGFlA5Fpa", "from": "16315551181", "text": {"body": "this is a text message"}, "type": "text", "timestamp": "1504902988", "from_user_id": "US.13491208655302741918"}	ABGGFlA5Fpa	\N	2017-09-08 20:36:28+00
6f37dd14-8f16-4fa9-993a-7d9499e70de7	f51d1fd9-3ac2-4095-9cf3-a64f477d142b	16315551181	outbound	text	Welcome to Techwheels. May I have your name?	{"route": "lead_capture", "source": "message_router", "conversation_id": "f51d1fd9-3ac2-4095-9cf3-a64f477d142b", "detected_intents": ["lead_capture"]}	\N	queued	2026-03-21 10:27:26.247+00
1491152b-363c-4670-b0ea-3cf65f5758d4	ec8b34ad-3324-44ea-8512-2972e81cc3f6	917424900000	inbound	text	Hi	{"id": "wamid.HBgMOTE3NDI0OTAwMDAwFQIAEhgUM0I1Qjg2RkQ1QzVDMUFENDkxMEQA", "from": "917424900000", "text": {"body": "Hi"}, "type": "text", "timestamp": "1774089115"}	wamid.HBgMOTE3NDI0OTAwMDAwFQIAEhgUM0I1Qjg2RkQ1QzVDMUFENDkxMEQA	\N	2026-03-21 10:31:55+00
23ca3935-51d0-4eea-bc45-49b81950183f	ec8b34ad-3324-44ea-8512-2972e81cc3f6	917424900000	outbound	text	I can help with price for Hyundai Creta, features, or the best variant. Do you want price, features, or best variant? I can also connect you with a human advisor.	{"route": "fallback", "source": "message_router", "conversation_id": "ec8b34ad-3324-44ea-8512-2972e81cc3f6", "detected_intents": ["greeting"]}	\N	queued	2026-03-21 10:32:01.218+00
69755ae8-7c3f-401c-ae82-36d1a7a324f7	193ab0dc-7592-45b9-8b3f-92e5042d4770	918963000000	inbound	text	Hi need price for tata nexon	{"id": "wamid.HBgMOTE4OTYzMDAwMDAwFQIAEhgUM0FBNkFDM0ZGN0EzRTZFNEY3OUQA", "from": "918963000000", "text": {"body": "Hi need price for tata nexon"}, "type": "text", "timestamp": "1773989554"}	wamid.HBgMOTE4OTYzMDAwMDAwFQIAEhgUM0FBNkFDM0ZGN0EzRTZFNEY3OUQA	\N	2026-03-20 06:52:34+00
48c06d6b-97f8-4344-a08a-4f5293aeec0e	193ab0dc-7592-45b9-8b3f-92e5042d4770	918963000000	outbound	text	Please choose one of these models: Hyundai Creta, Kia Seltos.	{"route": "lead_capture", "source": "message_router", "conversation_id": "193ab0dc-7592-45b9-8b3f-92e5042d4770", "detected_intents": ["lead_capture"]}	\N	queued	2026-03-21 10:35:00.154+00
e0a9d587-0953-4575-8b6e-e3bbdda3104a	ec8b34ad-3324-44ea-8512-2972e81cc3f6	917424900000	inbound	text	Hey	{"id": "wamid.HBgMOTE3NDI0OTAwMDAwFQIAEhgUM0E1N0Q4Q0I4MjkzNkI3OTcxQUEA", "from": "917424900000", "text": {"body": "Hey"}, "type": "text", "timestamp": "1774010087"}	wamid.HBgMOTE3NDI0OTAwMDAwFQIAEhgUM0E1N0Q4Q0I4MjkzNkI3OTcxQUEA	\N	2026-03-20 12:34:47+00
aa398a0b-84a8-4068-beee-00c5206c4c13	ec8b34ad-3324-44ea-8512-2972e81cc3f6	917424900000	outbound	text	I can help with price for Hyundai Creta, features, or the best variant. Do you want price, features, or best variant? I can also connect you with a human advisor.	{"route": "fallback", "source": "message_router", "conversation_id": "ec8b34ad-3324-44ea-8512-2972e81cc3f6", "detected_intents": ["greeting"]}	\N	queued	2026-03-21 12:01:48.726+00
f27cd0bf-f17d-4de9-8656-bdd0dfe08eec	193ab0dc-7592-45b9-8b3f-92e5042d4770	918963000000	inbound	text	Hells	{"id": "wamid.HBgMOTE4OTYzMDAwMDAwFQIAEhgUM0FBQ0I4N0JFOTFERkJCRDMwMDYA", "from": "918963000000", "text": {"body": "Hells"}, "type": "text", "timestamp": "1773992750"}	wamid.HBgMOTE4OTYzMDAwMDAwFQIAEhgUM0FBQ0I4N0JFOTFERkJCRDMwMDYA	\N	2026-03-20 07:45:50+00
a64d93ed-bd3c-47e3-9f58-265f50017687	193ab0dc-7592-45b9-8b3f-92e5042d4770	918963000000	outbound	text	Please choose one of these models: Altroz, Curvv, Harrier, Nexon, Punch2.0, Safari, Sierra, Tiago, Tigor, Xpres T.	{"route": "lead_capture", "source": "message_router", "conversation_id": "193ab0dc-7592-45b9-8b3f-92e5042d4770", "detected_intents": ["lead_capture"]}	\N	queued	2026-03-21 13:00:21.914+00
40765bb2-bc4a-4efe-b36c-b9f9263d3f78	193ab0dc-7592-45b9-8b3f-92e5042d4770	918963000000	inbound	text	Hi I need price for Tata neon	{"id": "wamid.HBgMOTE4OTYzMDAwMDAwFQIAEhgUM0NCQ0YwQzc3NUEyMUNFRUNFOTkA", "from": "918963000000", "text": {"body": "Hi I need price for Tata neon"}, "type": "text", "timestamp": "1773988916"}	wamid.HBgMOTE4OTYzMDAwMDAwFQIAEhgUM0NCQ0YwQzc3NUEyMUNFRUNFOTkA	\N	2026-03-20 06:41:56+00
79b01979-d13d-4742-a6e2-f552bf56e3d8	193ab0dc-7592-45b9-8b3f-92e5042d4770	918963000000	outbound	text	Please choose one of these models: Altroz, Curvv, Harrier, Nexon, Punch2.0, Safari, Sierra, Tiago, Tigor, Xpres T.	{"route": "lead_capture", "source": "message_router", "conversation_id": "193ab0dc-7592-45b9-8b3f-92e5042d4770", "detected_intents": ["lead_capture"]}	\N	queued	2026-03-21 16:43:32.965+00
c2982a71-14d9-4a65-a112-40614a4a5199	193ab0dc-7592-45b9-8b3f-92e5042d4770	918963000000	inbound	text	Hi need price for tata nexon	{"id": "wamid.HBgMOTE4OTYzMDAwMDAwFQIAEhgUM0EyNDFFNUEzMzQwQzk2NEZFQzUA", "from": "918963000000", "text": {"body": "Hi need price for tata nexon"}, "type": "text", "timestamp": "1773989472"}	wamid.HBgMOTE4OTYzMDAwMDAwFQIAEhgUM0EyNDFFNUEzMzQwQzk2NEZFQzUA	\N	2026-03-20 06:51:12+00
27e899dd-f572-43e4-8c18-13adf5184dfc	193ab0dc-7592-45b9-8b3f-92e5042d4770	918963000000	outbound	text	Got it. Which fuel type do you prefer: petrol, diesel, cng, or ev?	{"route": "lead_capture", "source": "message_router", "conversation_id": "193ab0dc-7592-45b9-8b3f-92e5042d4770", "detected_intents": ["lead_capture"]}	\N	queued	2026-03-21 17:18:21.625+00
2eae8f66-4f09-4359-87a2-e580a6f2ed0b	193ab0dc-7592-45b9-8b3f-92e5042d4770	918963000000	inbound	text	Hello	{"id": "wamid.HBgMOTE4OTYzMDAwMDAwFQIAEhgUM0E0NkZGQjE2QTNCQjhENTlEMTYA", "from": "918963000000", "text": {"body": "Hello"}, "type": "text", "timestamp": "1773991228"}	wamid.HBgMOTE4OTYzMDAwMDAwFQIAEhgUM0E0NkZGQjE2QTNCQjhENTlEMTYA	\N	2026-03-20 07:20:28+00
b021f93e-d6d0-4a50-ba1b-640403cc8d91	193ab0dc-7592-45b9-8b3f-92e5042d4770	918963000000	outbound	text	Please reply with one fuel type: petrol, diesel, cng, or ev.	{"route": "lead_capture", "source": "message_router", "conversation_id": "193ab0dc-7592-45b9-8b3f-92e5042d4770", "detected_intents": ["lead_capture"]}	\N	queued	2026-03-21 20:45:46.411+00
c546562b-00ff-4975-b3da-0f7147d5c5b8	193ab0dc-7592-45b9-8b3f-92e5042d4770	918963000000	inbound	text	Nexon	{"id": "wamid.HBgMOTE4OTYzMDAwMDAwFQIAEhgUM0MzMEU5OTM2RDI1OEMyMUM3MTUA", "from": "918963000000", "text": {"body": "Nexon"}, "type": "text", "timestamp": "1773988999"}	wamid.HBgMOTE4OTYzMDAwMDAwFQIAEhgUM0MzMEU5OTM2RDI1OEMyMUM3MTUA	\N	2026-03-20 06:43:19+00
be9e6c8e-02d4-4ca7-9a41-c1b88e15d3fc	193ab0dc-7592-45b9-8b3f-92e5042d4770	918963000000	outbound	text	Please reply with one fuel type: petrol, diesel, cng, or ev.	{"route": "lead_capture", "source": "message_router", "conversation_id": "193ab0dc-7592-45b9-8b3f-92e5042d4770", "detected_intents": ["lead_capture"]}	\N	queued	2026-03-21 21:16:40.081+00
74913e13-a0f9-46b6-adba-7ab7c4488760	193ab0dc-7592-45b9-8b3f-92e5042d4770	918963000000	inbound	text	Hi need price for tata nexon	{"id": "wamid.HBgMOTE4OTYzMDAwMDAwFQIAEhgUM0FFNkVBQ0Q5QkUwOTQwRUM4MTgA", "from": "918963000000", "text": {"body": "Hi need price for tata nexon"}, "type": "text", "timestamp": "1773989772"}	wamid.HBgMOTE4OTYzMDAwMDAwFQIAEhgUM0FFNkVBQ0Q5QkUwOTQwRUM4MTgA	\N	2026-03-20 06:56:12+00
0f4aaf14-39f1-4627-a413-dd0c7675533c	193ab0dc-7592-45b9-8b3f-92e5042d4770	918963000000	outbound	text	Please reply with one fuel type: petrol, diesel, cng, or ev.	{"route": "lead_capture", "source": "message_router", "conversation_id": "193ab0dc-7592-45b9-8b3f-92e5042d4770", "detected_intents": ["lead_capture"]}	\N	queued	2026-03-22 04:31:50.003+00
d38f902c-a20f-4553-9130-e98daa8035da	024ae476-57c7-4b87-8f44-6a8d18e1838d	918422939422	inbound	unsupported	\N	{"id": "wamid.HBgMOTE4NDIyOTM5NDIyFQIAEhgSMjRDOTNEQUNCMkJDRkRDQUY3AA==", "from": "918422939422", "type": "unsupported", "errors": [{"code": 131051, "title": "Message type unknown", "message": "Message type unknown", "error_data": {"details": "Message type is currently not supported."}}], "timestamp": "1774176097", "unsupported": {"type": "unknown"}}	wamid.HBgMOTE4NDIyOTM5NDIyFQIAEhgSMjRDOTNEQUNCMkJDRkRDQUY3AA==	\N	2026-03-22 10:41:37+00
43236f87-6ad7-45e2-ac52-6fe54b0b9411	024ae476-57c7-4b87-8f44-6a8d18e1838d	918422939422	outbound	text	Please share your name so I can help you better.	{"route": "lead_capture", "source": "message_router", "conversation_id": "024ae476-57c7-4b87-8f44-6a8d18e1838d", "detected_intents": ["lead_capture"]}	\N	queued	2026-03-22 10:41:44.435+00
\.


--
-- Data for Name: pricing_rules; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.pricing_rules (id, model, variant_id, rule_type, rule_name, value_type, value, is_stackable, conditions, is_active, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: variants; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.variants (id, model, variant_name, fuel_type, transmission, ex_showroom_price, brochure_url, is_active, created_at, updated_at, insurance, rto_standard, rto_rate, rto_bh, rto_scrap, scheme_consumer, scheme_exchange_scrap, scheme_additional_scrap, scheme_corporate, scheme_intervention, scheme_solar, scheme_msme, scheme_green_bonus) FROM stdin;
41951584-eafb-4c4a-9873-ccdafa986e6f	Altroz	CNG	Altroz Accomplished S CNG	Manual	1014590.00	https://drive.google.com/file/d/1B90tWP4vHjOVORd-2F4onzvFWnYyiLtJ/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	27637.00	107427.00	0.0000	21597.00	81745.00	15000.00	15000.00	40000.00	3000.00	0.00	0.00	0.00	0.00
5d61e363-73a9-44fa-969c-f1026630beb6	Altroz	CNG	Altroz Creative CNG	Manual	895690.00	https://drive.google.com/file/d/1B90tWP4vHjOVORd-2F4onzvFWnYyiLtJ/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	26174.00	95389.00	0.0000	20086.00	72717.00	15000.00	15000.00	40000.00	3000.00	0.00	0.00	0.00	0.00
b0a72c4b-48f2-492d-9252-48c87e3f1c7d	Altroz	CNG	Altroz Creative S CNG	Manual	914790.00	https://drive.google.com/file/d/1B90tWP4vHjOVORd-2F4onzvFWnYyiLtJ/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	26408.00	97322.00	0.0000	20329.00	74167.00	15000.00	15000.00	40000.00	3000.00	0.00	0.00	0.00	0.00
05e20f8c-9697-40f5-81c3-2465a5477109	Altroz	CNG	Altroz Pure CNG	Manual	804190.00	https://drive.google.com/file/d/1B90tWP4vHjOVORd-2F4onzvFWnYyiLtJ/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	25048.00	86124.00	0.0000	18923.00	65768.00	15000.00	15000.00	40000.00	3000.00	0.00	0.00	0.00	0.00
3b69823d-530d-4522-a407-4755374f9207	Altroz	CNG	Altroz Pure S CNG	Manual	837090.00	https://drive.google.com/file/d/1B90tWP4vHjOVORd-2F4onzvFWnYyiLtJ/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	25453.00	89455.00	0.0000	19341.00	68266.00	15000.00	15000.00	40000.00	3000.00	0.00	0.00	0.00	0.00
e29949cc-4237-46b6-a868-f690f72657e4	Altroz	CNG	Altroz Smart CNG	Manual	721890.00	https://drive.google.com/file/d/1B90tWP4vHjOVORd-2F4onzvFWnYyiLtJ/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	24034.00	77791.00	0.0000	17877.00	59518.00	15000.00	15000.00	40000.00	3000.00	0.00	0.00	0.00	0.00
a749a424-2223-437f-9318-e8b1b4370f75	Altroz	Diesel	Altroz Accomplished S 1.5	Manual	1017090.00	https://drive.google.com/file/d/1B90tWP4vHjOVORd-2F4onzvFWnYyiLtJ/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	27667.00	142007.00	0.0000	25939.00	107680.00	15000.00	15000.00	40000.00	3000.00	0.00	0.00	0.00	0.00
6df36c27-b609-4ee0-bd09-013da360c3ff	Altroz	Diesel	Altroz Creative S 1.5	Manual	932390.00	https://drive.google.com/file/d/1B90tWP4vHjOVORd-2F4onzvFWnYyiLtJ/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	26624.00	130573.00	0.0000	24503.00	99105.00	15000.00	15000.00	40000.00	3000.00	0.00	0.00	0.00	0.00
3bf3fa23-afae-49b0-85db-fddbf6660f8c	Altroz	Diesel	Altroz Pure 1.5	Manual	809890.00	https://drive.google.com/file/d/1B90tWP4vHjOVORd-2F4onzvFWnYyiLtJ/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	25117.00	114035.00	0.0000	22427.00	86701.00	15000.00	15000.00	40000.00	3000.00	0.00	0.00	0.00	0.00
af4ef502-ff23-4581-a712-a9e4df56861a	Altroz	Petrol	Altroz Accomplished S 1.2	Manual	913990.00	https://drive.google.com/file/d/1B90tWP4vHjOVORd-2F4onzvFWnYyiLtJ/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	26399.00	97241.00	0.0000	20319.00	74106.00	15000.00	15000.00	40000.00	3000.00	0.00	0.00	0.00	0.00
7d848ce6-da81-464b-804f-8ae2510a4691	Altroz	Petrol	Altroz Accomplished S DCA 1.2	DCA	1028290.00	https://drive.google.com/file/d/1B90tWP4vHjOVORd-2F4onzvFWnYyiLtJ/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	27806.00	108814.00	0.0000	21771.00	82786.00	15000.00	15000.00	40000.00	3000.00	0.00	0.00	0.00	0.00
2b1b2d82-f03e-4de5-b71e-76d4355f54c9	Altroz	Petrol	Altroz Accomplished+S DCA 1.2	DCA	1051190.00	https://drive.google.com/file/d/1B90tWP4vHjOVORd-2F4onzvFWnYyiLtJ/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	28088.00	111133.00	0.0000	22063.00	84525.00	15000.00	15000.00	40000.00	3000.00	0.00	0.00	0.00	0.00
f4dba417-3799-4ebf-a6d7-9043b52f72b1	Altroz	Petrol	Altroz Creative 1.2	Manual	794990.00	https://drive.google.com/file/d/1B90tWP4vHjOVORd-2F4onzvFWnYyiLtJ/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	24935.00	85193.00	0.0000	18806.00	65070.00	15000.00	15000.00	40000.00	3000.00	0.00	0.00	0.00	0.00
61e95927-0d68-4c77-b455-3571cc542db9	Altroz	Petrol	Altroz Creative AMT 1.2	Automatic	849890.00	https://drive.google.com/file/d/1B90tWP4vHjOVORd-2F4onzvFWnYyiLtJ/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	25610.00	90751.00	0.0000	19504.00	69238.00	15000.00	15000.00	40000.00	3000.00	0.00	0.00	0.00	0.00
556142c7-fad3-4602-8b81-1a8d38e682f4	Altroz	Petrol	Altroz Creative S 1.2	Manual	827990.00	https://drive.google.com/file/d/1B90tWP4vHjOVORd-2F4onzvFWnYyiLtJ/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	25341.00	88534.00	0.0000	19225.00	67576.00	15000.00	15000.00	40000.00	3000.00	0.00	0.00	0.00	0.00
ab0bf04c-5dc1-4542-9aa9-e0992ce54c51	Altroz	Petrol	Altroz Creative S AMT 1.2	Automatic	882890.00	https://drive.google.com/file/d/1B90tWP4vHjOVORd-2F4onzvFWnYyiLtJ/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	26015.00	94093.00	0.0000	19923.00	71745.00	15000.00	15000.00	40000.00	3000.00	0.00	0.00	0.00	0.00
5478393a-05ec-4dfe-91fa-8156959c677d	Altroz	Petrol	Altroz Creative S DCA 1.2	DCA	942290.00	https://drive.google.com/file/d/1B90tWP4vHjOVORd-2F4onzvFWnYyiLtJ/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	26747.00	100107.00	0.0000	20678.00	76255.00	15000.00	15000.00	40000.00	3000.00	0.00	0.00	0.00	0.00
9b586b2e-00ba-46e1-b713-cadeafdcbbed	Altroz	Petrol	Altroz Pure 1.2	Manual	703590.00	https://drive.google.com/file/d/1B90tWP4vHjOVORd-2F4onzvFWnYyiLtJ/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	23809.00	75938.00	0.0000	17644.00	58129.00	15000.00	15000.00	40000.00	3000.00	0.00	0.00	0.00	0.00
3a3e06bb-e685-4055-8be0-c04acc3d51a2	Altroz	Petrol	Altroz Pure AMT 1.2	Automatic	758490.00	https://drive.google.com/file/d/1B90tWP4vHjOVORd-2F4onzvFWnYyiLtJ/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	24485.00	81497.00	0.0000	18342.00	62298.00	15000.00	15000.00	40000.00	3000.00	0.00	0.00	0.00	0.00
1de00380-147e-4d3f-bf78-bc80122970ae	Altroz	Petrol	Altroz Pure S 1.2	Manual	736490.00	https://drive.google.com/file/d/1B90tWP4vHjOVORd-2F4onzvFWnYyiLtJ/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	24215.00	79270.00	0.0000	18062.00	60628.00	15000.00	15000.00	40000.00	3000.00	0.00	0.00	0.00	0.00
0881ee92-96c0-4eba-90c2-eef954a0db6d	Altroz	Petrol	Altroz Pure S AMT 1.2	Automatic	791390.00	https://drive.google.com/file/d/1B90tWP4vHjOVORd-2F4onzvFWnYyiLtJ/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	24890.00	84828.00	0.0000	18760.00	64796.00	15000.00	15000.00	40000.00	3000.00	0.00	0.00	0.00	0.00
63c329fd-1e3e-4b7d-ba82-e554f6c0a46d	Altroz	Petrol	Altroz Smart 1.2	Manual	630390.00	https://drive.google.com/file/d/1B90tWP4vHjOVORd-2F4onzvFWnYyiLtJ/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	22909.00	68527.00	0.0000	16713.00	52570.00	15000.00	15000.00	40000.00	3000.00	0.00	0.00	0.00	0.00
f5ac2d36-ab58-47ba-b1af-de28b998e06b	Curvv	Diesel	Curvv Accomplished S 1.5	Manual	1600190.00	https://drive.google.com/file/d/1ouZ3GiKKmSnGgBZXQ-NzhyoB9-tkI0V3/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	37506.00	220726.00	0.0000	31560.00	166720.00	20000.00	20000.00	55000.00	5000.00	0.00	0.00	0.00	0.00
39dbc54f-2b71-4a3e-92da-e91309b9d2e0	Curvv	Diesel	Curvv Accomplished S DCA 1.5	DCA	1745090.00	https://drive.google.com/file/d/1ouZ3GiKKmSnGgBZXQ-NzhyoB9-tkI0V3/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	39391.00	240287.00	0.0000	33630.00	181390.00	20000.00	20000.00	55000.00	5000.00	0.00	0.00	0.00	0.00
406f9975-5530-4341-b5b3-ffbcb79bd3d7	Curvv	Diesel	Curvv Accomplished S DCA DK1.5	DCA	1756390.00	https://drive.google.com/file/d/1ouZ3GiKKmSnGgBZXQ-NzhyoB9-tkI0V3/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	39538.00	241813.00	0.0000	33791.00	182535.00	20000.00	20000.00	55000.00	5000.00	0.00	0.00	0.00	0.00
c6ba4000-f95e-4b3a-8bfe-615843c2b323	Curvv	Diesel	Curvv Accomplished S DK 1.5	Manual	1611590.00	https://drive.google.com/file/d/1ouZ3GiKKmSnGgBZXQ-NzhyoB9-tkI0V3/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	37654.00	222265.00	0.0000	31723.00	167874.00	20000.00	20000.00	55000.00	5000.00	0.00	0.00	0.00	0.00
e2da68a3-b612-49d1-8cb2-c4ad83a2b6f7	Curvv	Diesel	Curvv Accomplished+A 1.5	Manual	1728590.00	https://drive.google.com/file/d/1ouZ3GiKKmSnGgBZXQ-NzhyoB9-tkI0V3/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	39176.00	238060.00	0.0000	33394.00	179720.00	20000.00	20000.00	55000.00	5000.00	0.00	0.00	0.00	0.00
94c8a9e8-8bb5-4b3a-8dae-d7353fbcd199	Curvv	Diesel	Curvv Accomplished+A DCA 1.5	DCA	1873490.00	https://drive.google.com/file/d/1ouZ3GiKKmSnGgBZXQ-NzhyoB9-tkI0V3/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	41062.00	257621.00	0.0000	35464.00	194391.00	20000.00	20000.00	55000.00	5000.00	0.00	0.00	0.00	0.00
c2796f42-5066-41db-b229-13a7a5d87c7f	Curvv	Diesel	Curvv Accomplished+A DCA DK1.5	DCA	1884790.00	https://drive.google.com/file/d/1ouZ3GiKKmSnGgBZXQ-NzhyoB9-tkI0V3/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	41209.00	259147.00	0.0000	35626.00	195535.00	20000.00	20000.00	55000.00	5000.00	0.00	0.00	0.00	0.00
737d551d-2f46-4ee0-8318-1204e2029d7e	Curvv	Diesel	Curvv Accomplished+A DK 1.5	Manual	1739990.00	https://drive.google.com/file/d/1ouZ3GiKKmSnGgBZXQ-NzhyoB9-tkI0V3/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	39325.00	239599.00	0.0000	33557.00	180874.00	20000.00	20000.00	55000.00	5000.00	0.00	0.00	0.00	0.00
241e3788-0e1c-49b3-8712-ab28dd736168	Curvv	Diesel	Curvv Creative 1.5	Manual	1351890.00	https://drive.google.com/file/d/1ouZ3GiKKmSnGgBZXQ-NzhyoB9-tkI0V3/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	34275.00	187205.00	0.0000	28013.00	141579.00	20000.00	20000.00	55000.00	5000.00	0.00	0.00	0.00	0.00
45a83ec1-d1c4-4bd1-916e-96159e2e8861	Curvv	Diesel	Curvv Creative S 1.5	Manual	1400090.00	https://drive.google.com/file/d/1ouZ3GiKKmSnGgBZXQ-NzhyoB9-tkI0V3/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	34902.00	193712.00	0.0000	28701.00	146459.00	20000.00	20000.00	55000.00	5000.00	0.00	0.00	0.00	0.00
4498ea3d-a4a0-4b1d-93c9-9f6dee828832	Curvv	Diesel	Curvv Creative S DCA 1.5	DCA	1544990.00	https://drive.google.com/file/d/1ouZ3GiKKmSnGgBZXQ-NzhyoB9-tkI0V3/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	36788.00	213274.00	0.0000	30771.00	161131.00	20000.00	20000.00	55000.00	5000.00	0.00	0.00	0.00	0.00
e04dfef9-c73e-4e93-99bb-119093f9a94b	Curvv	Diesel	Curvv Creative+S 1.5	Manual	1503690.00	https://drive.google.com/file/d/1ouZ3GiKKmSnGgBZXQ-NzhyoB9-tkI0V3/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	36251.00	207698.00	0.0000	30181.00	156949.00	20000.00	20000.00	55000.00	5000.00	0.00	0.00	0.00	0.00
7f7bdbee-5ff2-42e4-b725-e0b0557f108e	Curvv	Diesel	Curvv Creative+S DCA 1.5	DCA	1648490.00	https://drive.google.com/file/d/1ouZ3GiKKmSnGgBZXQ-NzhyoB9-tkI0V3/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	38135.00	227246.00	0.0000	32250.00	171610.00	20000.00	20000.00	55000.00	5000.00	0.00	0.00	0.00	0.00
d77c17e8-bce5-415c-ab09-b35427d11209	Curvv	Diesel	Curvv Pure+ 1.5	Manual	1235990.00	https://drive.google.com/file/d/1ouZ3GiKKmSnGgBZXQ-NzhyoB9-tkI0V3/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	32766.00	171559.00	0.0000	26357.00	129844.00	20000.00	20000.00	55000.00	5000.00	0.00	0.00	0.00	0.00
68a5d702-ec79-4dbe-b3c8-897e7ced6eba	Curvv	Diesel	Curvv Pure+ DCA 1.5	DCA	1380790.00	https://drive.google.com/file/d/1ouZ3GiKKmSnGgBZXQ-NzhyoB9-tkI0V3/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	34652.00	191107.00	0.0000	28426.00	144505.00	20000.00	20000.00	55000.00	5000.00	0.00	0.00	0.00	0.00
f4ead478-4dd6-46b7-a845-97f2ee7a8bc9	Curvv	Diesel	Curvv Pure+S 1.5	Manual	1303590.00	https://drive.google.com/file/d/1ouZ3GiKKmSnGgBZXQ-NzhyoB9-tkI0V3/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	33647.00	180685.00	0.0000	27323.00	136689.00	20000.00	20000.00	55000.00	5000.00	0.00	0.00	0.00	0.00
8ceb6bc2-43db-4822-acdd-6ba0f8910a68	Curvv	Diesel	Curvv Pure+S DCA 1.5	DCA	1448390.00	https://drive.google.com/file/d/1ouZ3GiKKmSnGgBZXQ-NzhyoB9-tkI0V3/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	35531.00	200233.00	0.0000	29391.00	151350.00	20000.00	20000.00	55000.00	5000.00	0.00	0.00	0.00	0.00
52a7a4c4-9b84-4f48-aed0-376e6b643698	Curvv	Diesel	Curvv Smart 1.5	Manual	1110490.00	https://drive.google.com/file/d/1ouZ3GiKKmSnGgBZXQ-NzhyoB9-tkI0V3/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	31134.00	154616.00	0.0000	24564.00	117137.00	20000.00	20000.00	55000.00	5000.00	0.00	0.00	0.00	0.00
d736383e-bf3e-4a15-b6ce-3d792d3a61da	Curvv	EV	Curvv EV Accomplished + S 45	Automatic	1929000.00	https://drive.google.com/file/d/11rDzu39hiDPbHvcX__S2wtb8f4yugl3K/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	54199.00	2200.00	0.0000	2200.00	1600.00	0.00	30000.00	35000.00	0.00	0.00	10000.00	10000.00	300000.00
a1b33531-ce99-4e87-ad53-2423ce357937	Curvv	EV	Curvv EV Accomplished 45	Automatic	1849000.00	https://drive.google.com/file/d/11rDzu39hiDPbHvcX__S2wtb8f4yugl3K/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	53170.00	2200.00	0.0000	2200.00	1600.00	0.00	30000.00	35000.00	0.00	0.00	10000.00	10000.00	300000.00
0fdda153-00b9-4726-8ef7-1dad2d7a3ae8	Curvv	EV	Curvv EV Accomplished 55	Automatic	1925000.00	https://drive.google.com/file/d/11rDzu39hiDPbHvcX__S2wtb8f4yugl3K/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	54148.00	2200.00	0.0000	2200.00	1600.00	0.00	30000.00	35000.00	0.00	0.00	10000.00	10000.00	300000.00
65080134-b87e-4160-aa63-93d97d791bca	Curvv	EV	Curvv EV Accomplished+ S 55	Automatic	1999000.00	https://drive.google.com/file/d/11rDzu39hiDPbHvcX__S2wtb8f4yugl3K/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	55099.00	2200.00	0.0000	2200.00	1600.00	0.00	30000.00	35000.00	0.00	0.00	10000.00	10000.00	300000.00
fcf2b3e9-8132-449e-8eb2-16d6b3db3166	Curvv	EV	Curvv EV Creative 45	Automatic	1749000.00	https://drive.google.com/file/d/11rDzu39hiDPbHvcX__S2wtb8f4yugl3K/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	51883.00	2200.00	0.0000	2200.00	1600.00	0.00	30000.00	35000.00	0.00	0.00	10000.00	10000.00	250000.00
cd77ae6b-fe2f-4f53-b77c-d1cf9d722a86	Curvv	EV	Curvv EV Empowered+ 55	Automatic	2125000.00	https://drive.google.com/file/d/11rDzu39hiDPbHvcX__S2wtb8f4yugl3K/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	56719.00	2200.00	0.0000	2200.00	1600.00	0.00	30000.00	35000.00	0.00	0.00	10000.00	10000.00	300000.00
eb084167-79fd-4640-8b14-fe965492d7bc	Curvv	EV	Curvv EV Empowered+ A 55	Automatic	2199000.00	https://drive.google.com/file/d/11rDzu39hiDPbHvcX__S2wtb8f4yugl3K/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	57671.00	2200.00	0.0000	2200.00	1600.00	0.00	30000.00	35000.00	0.00	0.00	10000.00	10000.00	300000.00
3e65e6ca-ffeb-4e0c-901d-d5ea029aada3	Curvv	EV	Curvv EV Empowered+A 55 DK	Automatic	2224000.00	https://drive.google.com/file/d/11rDzu39hiDPbHvcX__S2wtb8f4yugl3K/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	57993.00	2200.00	0.0000	2200.00	1600.00	0.00	30000.00	35000.00	0.00	0.00	10000.00	10000.00	300000.00
a073d59c-1e10-4d39-990d-e86d90f5467a	Curvv	Petrol	Curvv Accomplished S 1.2	Manual	1455390.00	https://drive.google.com/file/d/1ouZ3GiKKmSnGgBZXQ-NzhyoB9-tkI0V3/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	35622.00	152058.00	0.0000	24293.00	115219.00	20000.00	20000.00	45000.00	5000.00	0.00	0.00	0.00	0.00
a7360d24-1ccd-4b8c-b36b-68470087892f	Curvv	Petrol	Curvv Accomplished S 1.2 GDI	Manual	1571290.00	https://drive.google.com/file/d/1ouZ3GiKKmSnGgBZXQ-NzhyoB9-tkI0V3/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	37130.00	163793.00	0.0000	25535.00	124020.00	20000.00	20000.00	45000.00	5000.00	0.00	0.00	0.00	0.00
468c5248-87ca-4381-baca-12822e2cc1b8	Curvv	Petrol	Curvv Accomplished S DCA 1.2	DCA	1600190.00	https://drive.google.com/file/d/1ouZ3GiKKmSnGgBZXQ-NzhyoB9-tkI0V3/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	37506.00	166719.00	0.0000	25845.00	126214.00	20000.00	20000.00	45000.00	5000.00	0.00	0.00	0.00	0.00
32c2a2e9-64e9-4ce5-9d9c-5cf016d3c4c5	Curvv	Petrol	Curvv Accomplished S DCA1.2GDI	DCA	1716090.00	https://drive.google.com/file/d/1ouZ3GiKKmSnGgBZXQ-NzhyoB9-tkI0V3/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	39014.00	178454.00	0.0000	27087.00	135016.00	20000.00	20000.00	45000.00	5000.00	0.00	0.00	0.00	0.00
4bd501c7-a68a-4809-8c5f-32e87cdc2812	Curvv	Petrol	Curvv Accomplished S DCA DKGDI	DCA	1737090.00	https://drive.google.com/file/d/1ouZ3GiKKmSnGgBZXQ-NzhyoB9-tkI0V3/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	39288.00	180580.00	0.0000	27312.00	136610.00	20000.00	20000.00	45000.00	5000.00	0.00	0.00	0.00	0.00
39b43251-3a80-4efa-8daa-fb53ef20156b	Curvv	Petrol	Curvv Accomplished S DK 1.2GDI	Manual	1592290.00	https://drive.google.com/file/d/1ouZ3GiKKmSnGgBZXQ-NzhyoB9-tkI0V3/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	37404.00	165919.00	0.0000	25760.00	125614.00	20000.00	20000.00	45000.00	5000.00	0.00	0.00	0.00	0.00
2adf5943-cdd6-4bcc-88e6-e37b9a7882d8	Curvv	Petrol	Curvv Accomplished+A 1.2GDI	Manual	1716090.00	https://drive.google.com/file/d/1ouZ3GiKKmSnGgBZXQ-NzhyoB9-tkI0V3/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	39014.00	178454.00	0.0000	27087.00	135016.00	20000.00	20000.00	45000.00	5000.00	0.00	0.00	0.00	0.00
560c1188-9e82-4dcd-aefe-76545ab2137c	Curvv	Petrol	Curvv Accomplished+A DCA DKGDI	DCA	1881890.00	https://drive.google.com/file/d/1ouZ3GiKKmSnGgBZXQ-NzhyoB9-tkI0V3/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	41171.00	195241.00	0.0000	28863.00	147606.00	20000.00	20000.00	45000.00	5000.00	0.00	0.00	0.00	0.00
cc762e63-9ad2-4a71-ab60-1b668a45f31c	Curvv	Petrol	Curvv Accomplished+A DCA1.2GDI	DCA	1860890.00	https://drive.google.com/file/d/1ouZ3GiKKmSnGgBZXQ-NzhyoB9-tkI0V3/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	40899.00	193115.00	0.0000	28638.00	146011.00	20000.00	20000.00	45000.00	5000.00	0.00	0.00	0.00	0.00
dcb7a1b6-bf94-4901-9801-eb49162c5b28	Curvv	Petrol	Curvv Accomplished+A DK 1.2GDI	Manual	1737090.00	https://drive.google.com/file/d/1ouZ3GiKKmSnGgBZXQ-NzhyoB9-tkI0V3/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	39288.00	180580.00	0.0000	27312.00	136610.00	20000.00	20000.00	45000.00	5000.00	0.00	0.00	0.00	0.00
1798587d-ca9e-46c5-baaf-1ddb9ebb7ad6	Curvv	Petrol	Curvv Creative 1.2	Manual	1206990.00	https://drive.google.com/file/d/1ouZ3GiKKmSnGgBZXQ-NzhyoB9-tkI0V3/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	32390.00	126908.00	0.0000	21632.00	96356.00	20000.00	20000.00	45000.00	5000.00	0.00	0.00	0.00	0.00
b6bc6aab-cec0-47ce-834e-2f216843c600	Curvv	Petrol	Curvv Creative DCA 1.2	DCA	1351890.00	https://drive.google.com/file/d/1ouZ3GiKKmSnGgBZXQ-NzhyoB9-tkI0V3/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	34275.00	141579.00	0.0000	23185.00	107359.00	20000.00	20000.00	45000.00	5000.00	0.00	0.00	0.00	0.00
339c2e2e-3f7e-4213-b51a-3a59dba8918d	Curvv	Petrol	Curvv Creative S 1.2 GDI	Manual	1371190.00	https://drive.google.com/file/d/1ouZ3GiKKmSnGgBZXQ-NzhyoB9-tkI0V3/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	34527.00	143533.00	0.0000	23391.00	108825.00	20000.00	20000.00	45000.00	5000.00	0.00	0.00	0.00	0.00
7aa92d81-07dc-4c99-949a-58dc61e9a093	Curvv	Petrol	Curvv Creative S DCA 1.2	DCA	1400090.00	https://drive.google.com/file/d/1ouZ3GiKKmSnGgBZXQ-NzhyoB9-tkI0V3/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	34902.00	146459.00	0.0000	23701.00	111019.00	20000.00	20000.00	45000.00	5000.00	0.00	0.00	0.00	0.00
a0f3e7d8-e38b-432b-98af-e70373b54ee1	Curvv	Petrol	Curvv Creative+S 1.2	Manual	1358890.00	https://drive.google.com/file/d/1ouZ3GiKKmSnGgBZXQ-NzhyoB9-tkI0V3/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	34366.00	142288.00	0.0000	23260.00	107891.00	20000.00	20000.00	45000.00	5000.00	0.00	0.00	0.00	0.00
d0361729-c9fe-4f42-9cae-6bcaf910ebd6	Curvv	Petrol	Curvv Creative+S 1.2GDI	Manual	1474690.00	https://drive.google.com/file/d/1ouZ3GiKKmSnGgBZXQ-NzhyoB9-tkI0V3/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	35873.00	154012.00	0.0000	24500.00	116684.00	20000.00	20000.00	45000.00	5000.00	0.00	0.00	0.00	0.00
70b6c442-1347-42a5-bea2-b3a898c01e21	Curvv	Petrol	Curvv Creative+S DCA 1.2	DCA	1503690.00	https://drive.google.com/file/d/1ouZ3GiKKmSnGgBZXQ-NzhyoB9-tkI0V3/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	36251.00	156949.00	0.0000	24811.00	118887.00	20000.00	20000.00	45000.00	5000.00	0.00	0.00	0.00	0.00
9cff4af6-08fd-40aa-bc93-793aa17207eb	Curvv	Petrol	Curvv Creative+S DCA 1.2GDI	DCA	1619490.00	https://drive.google.com/file/d/1ouZ3GiKKmSnGgBZXQ-NzhyoB9-tkI0V3/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	37756.00	168673.00	0.0000	26052.00	127680.00	20000.00	20000.00	45000.00	5000.00	0.00	0.00	0.00	0.00
a9c91059-a513-4561-a38f-f0ffe8ade5a4	Curvv	Petrol	Curvv Pure+ 1.2	Manual	1091190.00	https://drive.google.com/file/d/1ouZ3GiKKmSnGgBZXQ-NzhyoB9-tkI0V3/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	30883.00	115183.00	0.0000	20391.00	87562.00	20000.00	20000.00	45000.00	5000.00	0.00	0.00	0.00	0.00
83bf41d8-7955-4f05-841c-a27cfdf57f97	Curvv	Petrol	Curvv Pure+ DCA 1.2	DCA	1235990.00	https://drive.google.com/file/d/1ouZ3GiKKmSnGgBZXQ-NzhyoB9-tkI0V3/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	32766.00	129844.00	0.0000	21943.00	98558.00	20000.00	20000.00	45000.00	5000.00	0.00	0.00	0.00	0.00
f6ae10fa-55b7-4bfc-a183-a6d34031b1bd	Curvv	Petrol	Curvv Pure+S 1.2	Manual	1158790.00	https://drive.google.com/file/d/1ouZ3GiKKmSnGgBZXQ-NzhyoB9-tkI0V3/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	31762.00	122027.00	0.0000	21116.00	92695.00	20000.00	20000.00	45000.00	5000.00	0.00	0.00	0.00	0.00
2c4dbe5d-532f-4301-8ffe-a9750a702aff	Curvv	Petrol	Curvv Pure+S DCA 1.2	DCA	1303590.00	https://drive.google.com/file/d/1ouZ3GiKKmSnGgBZXQ-NzhyoB9-tkI0V3/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	33647.00	136688.00	0.0000	22667.00	103691.00	20000.00	20000.00	45000.00	5000.00	0.00	0.00	0.00	0.00
3ce6be8a-25a4-4aba-9be6-ed17f9bc55e7	Curvv	Petrol	Curvv Smart 1.2	Manual	965690.00	https://drive.google.com/file/d/1ouZ3GiKKmSnGgBZXQ-NzhyoB9-tkI0V3/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	29250.00	102476.00	0.0000	19047.00	78032.00	20000.00	20000.00	45000.00	5000.00	0.00	0.00	0.00	0.00
c3bac2f3-9829-4c68-8473-08a18dc46fd3	Harrier	Diesel	Harrier Adventure X	Manual	1796490.00	https://drive.google.com/file/d/1Li1FzGuVaptdcrOfOgi1Ab-wFnHsgcWa/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	56896.00	248226.00	0.0000	35364.00	187595.00	10000.00	25000.00	70000.00	8000.00	20000.00	0.00	0.00	0.00
9744c66c-cb71-4e02-8ab1-fb2cfeb08a93	Harrier	Diesel	Harrier Adventure X AT	Automatic	1957290.00	https://drive.google.com/file/d/1Li1FzGuVaptdcrOfOgi1Ab-wFnHsgcWa/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	58969.00	269934.00	0.0000	37661.00	203876.00	10000.00	25000.00	70000.00	8000.00	20000.00	0.00	0.00	0.00
2621abc0-c053-4d93-9594-f8a5016dabd7	Harrier	Diesel	Harrier Adventure X DK	Manual	1848490.00	https://drive.google.com/file/d/1Li1FzGuVaptdcrOfOgi1Ab-wFnHsgcWa/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	57566.00	255246.00	0.0000	36107.00	192860.00	10000.00	25000.00	70000.00	8000.00	20000.00	0.00	0.00	0.00
93db876e-2451-4273-b9a1-fa69cbf36c77	Harrier	Diesel	Harrier Adventure X DK AT	Automatic	1999990.00	https://drive.google.com/file/d/1Li1FzGuVaptdcrOfOgi1Ab-wFnHsgcWa/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	59519.00	275699.00	0.0000	38271.00	208199.00	10000.00	25000.00	70000.00	8000.00	20000.00	0.00	0.00	0.00
d0cf1f3a-53ea-47d6-a990-854d5b242f9e	Harrier	Diesel	Harrier Adventure X+	Manual	1829590.00	https://drive.google.com/file/d/1Li1FzGuVaptdcrOfOgi1Ab-wFnHsgcWa/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	57323.00	252695.00	0.0000	35837.00	190946.00	10000.00	25000.00	70000.00	8000.00	20000.00	0.00	0.00	0.00
af9ef710-7fac-4897-87be-529730ba3967	Harrier	Diesel	Harrier Adventure X+ AT	Automatic	1990390.00	https://drive.google.com/file/d/1Li1FzGuVaptdcrOfOgi1Ab-wFnHsgcWa/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	59395.00	274403.00	0.0000	38134.00	207227.00	10000.00	25000.00	70000.00	8000.00	20000.00	0.00	0.00	0.00
9819cf7f-503e-4b94-a246-a24d9bd5ca5a	Harrier	Diesel	Harrier Adventure X+ DK	Manual	1881590.00	https://drive.google.com/file/d/1Li1FzGuVaptdcrOfOgi1Ab-wFnHsgcWa/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	57993.00	259715.00	0.0000	36580.00	196211.00	10000.00	25000.00	70000.00	8000.00	20000.00	0.00	0.00	0.00
0e25c3db-7b67-42dd-a5cb-61ff8ecf5d13	Harrier	Diesel	Harrier Adventure X+ DK AT	Automatic	2042390.00	https://drive.google.com/file/d/1Li1FzGuVaptdcrOfOgi1Ab-wFnHsgcWa/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	60066.00	281423.00	0.0000	38877.00	212492.00	10000.00	25000.00	70000.00	8000.00	20000.00	0.00	0.00	0.00
f996fa0c-3914-44df-a9f3-ed7b8b310427	Harrier	Diesel	Harrier Fearless + DT (AT)	Manual	2435801.00	https://drive.google.com/file/d/1Li1FzGuVaptdcrOfOgi1Ab-wFnHsgcWa/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	65136.00	334533.00	0.0000	44497.00	252325.00	10000.00	25000.00	70000.00	8000.00	20000.00	0.00	0.00	0.00
14f8e4b7-9815-4813-a85c-5324ea02aa07	Harrier	Diesel	Harrier Fearless X	Manual	2113390.00	https://drive.google.com/file/d/1Li1FzGuVaptdcrOfOgi1Ab-wFnHsgcWa/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	60981.00	291008.00	0.0000	39891.00	219681.00	10000.00	25000.00	70000.00	8000.00	20000.00	0.00	0.00	0.00
5180b9e5-8293-40fa-894a-810b136415ee	Harrier	Diesel	Harrier Fearless X AT	Automatic	2278890.00	https://drive.google.com/file/d/1Li1FzGuVaptdcrOfOgi1Ab-wFnHsgcWa/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	63113.00	313350.00	0.0000	42256.00	236438.00	10000.00	25000.00	70000.00	8000.00	20000.00	0.00	0.00	0.00
07833b21-2910-400c-b710-b8551d8d4b42	Harrier	Diesel	Harrier Fearless X DK	Manual	2165390.00	https://drive.google.com/file/d/1Li1FzGuVaptdcrOfOgi1Ab-wFnHsgcWa/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	61650.00	298028.00	0.0000	40634.00	224946.00	10000.00	25000.00	70000.00	8000.00	20000.00	0.00	0.00	0.00
b0a52bc1-5eac-432c-8fd1-3576c369f4ed	Harrier	Diesel	Harrier Fearless X DK AT	Automatic	2330890.00	https://drive.google.com/file/d/1Li1FzGuVaptdcrOfOgi1Ab-wFnHsgcWa/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	63784.00	320370.00	0.0000	42998.00	241703.00	10000.00	25000.00	70000.00	8000.00	20000.00	0.00	0.00	0.00
156b1924-876c-4553-b75e-6e4f4bddc2c2	Harrier	Diesel	Harrier Fearless X+	Manual	2311990.00	https://drive.google.com/file/d/1Li1FzGuVaptdcrOfOgi1Ab-wFnHsgcWa/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	63539.00	317819.00	0.0000	42728.00	239789.00	10000.00	25000.00	70000.00	8000.00	20000.00	0.00	0.00	0.00
cad9117f-b762-48dd-887d-9522673e0957	Harrier	Diesel	Harrier Fearless X+ AT	Automatic	2453890.00	https://drive.google.com/file/d/1Li1FzGuVaptdcrOfOgi1Ab-wFnHsgcWa/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	65370.00	336975.00	0.0000	44756.00	254156.00	10000.00	25000.00	70000.00	8000.00	20000.00	0.00	0.00	0.00
87584624-b669-4bf1-b441-9649e85c4b26	Harrier	Diesel	Harrier Fearless X+ AT STLTH	Automatic	2524890.00	https://drive.google.com/file/d/1Li1FzGuVaptdcrOfOgi1Ab-wFnHsgcWa/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	66284.00	346560.00	0.0000	45770.00	261345.00	10000.00	25000.00	70000.00	8000.00	20000.00	0.00	0.00	0.00
cb9a1db9-d884-4c35-a2f8-b42a0354ac83	Harrier	Diesel	Harrier Fearless X+ DK	Manual	2363990.00	https://drive.google.com/file/d/1Li1FzGuVaptdcrOfOgi1Ab-wFnHsgcWa/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	64210.00	324839.00	0.0000	43471.00	245054.00	10000.00	25000.00	70000.00	8000.00	20000.00	0.00	0.00	0.00
5501dca1-8a16-4e6c-91a5-afdbc5ceddc7	Harrier	Diesel	Harrier Fearless X+ DK AT	Automatic	2505890.00	https://drive.google.com/file/d/1Li1FzGuVaptdcrOfOgi1Ab-wFnHsgcWa/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	66039.00	343995.00	0.0000	45498.00	259421.00	10000.00	25000.00	70000.00	8000.00	20000.00	0.00	0.00	0.00
b416ec83-8e3c-466e-b075-5ff57f3c8075	Harrier	Diesel	Harrier Fearless X+ STLTH	Manual	2382990.00	https://drive.google.com/file/d/1Li1FzGuVaptdcrOfOgi1Ab-wFnHsgcWa/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	64455.00	327404.00	0.0000	43743.00	246978.00	10000.00	25000.00	70000.00	8000.00	20000.00	0.00	0.00	0.00
6df31348-2b3c-47e3-badd-2c924957537e	Harrier	Diesel	Harrier Pure	Manual	1593896.00	https://drive.google.com/file/d/1Li1FzGuVaptdcrOfOgi1Ab-wFnHsgcWa/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	54285.00	220878.00	0.0000	32470.00	167084.00	0.00	0.00	70000.00	0.00	20000.00	0.00	0.00	0.00
454a301e-9d70-44bd-bea9-d9331ee5450e	Harrier	Diesel	Harrier Pure X	Manual	1699990.00	https://drive.google.com/file/d/1Li1FzGuVaptdcrOfOgi1Ab-wFnHsgcWa/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	55652.00	235199.00	0.0000	33986.00	177824.00	10000.00	25000.00	70000.00	8000.00	20000.00	0.00	0.00	0.00
c9d6df78-53b3-45c7-b775-072db451aa96	Harrier	Diesel	Harrier Pure X AT	Automatic	1853190.00	https://drive.google.com/file/d/1Li1FzGuVaptdcrOfOgi1Ab-wFnHsgcWa/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	57626.00	255881.00	0.0000	36174.00	193336.00	10000.00	25000.00	70000.00	8000.00	20000.00	0.00	0.00	0.00
8c0bcf90-6dd2-4665-8694-13cd43f998d4	Harrier	Diesel	Harrier Pure X DK	Manual	1763390.00	https://drive.google.com/file/d/1Li1FzGuVaptdcrOfOgi1Ab-wFnHsgcWa/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	56470.00	243758.00	0.0000	34891.00	184244.00	10000.00	25000.00	70000.00	8000.00	20000.00	0.00	0.00	0.00
0eda06ff-6437-48f9-a8c9-e81146c523a7	Harrier	Diesel	Harrier Pure X DK AT	Automatic	1891090.00	https://drive.google.com/file/d/1Li1FzGuVaptdcrOfOgi1Ab-wFnHsgcWa/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	58116.00	260997.00	0.0000	36716.00	197173.00	10000.00	25000.00	70000.00	8000.00	20000.00	0.00	0.00	0.00
f1c60f8d-cd4c-4da0-adf8-0ea67dd46779	Harrier	Diesel	Harrier Smart	Manual	1399990.00	https://drive.google.com/file/d/1Li1FzGuVaptdcrOfOgi1Ab-wFnHsgcWa/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	52030.00	194699.00	0.0000	29700.00	147449.00	10000.00	25000.00	70000.00	8000.00	20000.00	0.00	0.00	0.00
d027e8c5-6c5c-49d9-9605-fea0044d2bc3	Harrier	EV	Harrier EV Adventure 65	Automatic	2149000.00	https://drive.google.com/file/d/1tTb8zpZS8PGZX6iNVEAUYPWZuIGVECw2/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	57955.00	2200.00	0.0000	2200.00	1600.00	0.00	50000.00	75000.00	0.00	0.00	0.00	0.00	100000.00
613a527e-e44e-455b-89de-833c3bd45d50	Harrier	EV	Harrier EV Adventure 65 ACFC	Automatic	2198000.00	https://drive.google.com/file/d/1tTb8zpZS8PGZX6iNVEAUYPWZuIGVECw2/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	58620.00	2200.00	0.0000	2200.00	1600.00	0.00	50000.00	75000.00	0.00	0.00	0.00	0.00	100000.00
f9033d1c-c52f-4a3e-9654-41a785a192d3	Harrier	EV	Harrier EV Adventure S 65	Automatic	2199000.00	https://drive.google.com/file/d/1tTb8zpZS8PGZX6iNVEAUYPWZuIGVECw2/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	58620.00	2200.00	0.0000	2200.00	1600.00	0.00	50000.00	75000.00	0.00	0.00	0.00	0.00	100000.00
2baaa6b7-2ad0-4792-a519-c6bcea5d5b97	Harrier	EV	Harrier EV Adventure S 65 ACFC	Automatic	2248000.00	https://drive.google.com/file/d/1tTb8zpZS8PGZX6iNVEAUYPWZuIGVECw2/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	59271.00	2200.00	0.0000	2200.00	1600.00	0.00	50000.00	75000.00	0.00	0.00	0.00	0.00	100000.00
980d3724-cb0f-4253-9b22-b9cb9bc1ab5b	Harrier	EV	Harrier EV Empowered 75	Automatic	2749000.00	https://drive.google.com/file/d/1tTb8zpZS8PGZX6iNVEAUYPWZuIGVECw2/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	65930.00	2200.00	0.0000	2200.00	1600.00	0.00	50000.00	75000.00	0.00	0.00	0.00	0.00	100000.00
f34b7b8d-abd4-48cf-815f-f2536eb679b0	Harrier	EV	Harrier EV Empowered 75 ACFC	Automatic	2798000.00	https://drive.google.com/file/d/1tTb8zpZS8PGZX6iNVEAUYPWZuIGVECw2/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	66582.00	2200.00	0.0000	2200.00	1600.00	0.00	50000.00	75000.00	0.00	0.00	0.00	0.00	100000.00
67087a52-9584-4c80-8213-b0d93ebdf712	Harrier	EV	Harrier EV Empowered AWD 75	Automatic	2899000.00	https://drive.google.com/file/d/1tTb8zpZS8PGZX6iNVEAUYPWZuIGVECw2/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	67924.00	2200.00	0.0000	2200.00	1600.00	0.00	50000.00	75000.00	0.00	0.00	0.00	0.00	100000.00
cfb306bf-111a-43fd-a984-bf6dd8b1fd2d	Harrier	EV	Harrier EV Empowered AWD ST 75	Automatic	2974000.00	https://drive.google.com/file/d/1tTb8zpZS8PGZX6iNVEAUYPWZuIGVECw2/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	68921.00	2200.00	0.0000	2200.00	1600.00	0.00	50000.00	75000.00	0.00	0.00	0.00	0.00	100000.00
02f328fa-4d04-49f7-a0bb-8834c9717766	Harrier	EV	Harrier EV Empowered AWD75ACFC	Automatic	2948000.00	https://drive.google.com/file/d/1tTb8zpZS8PGZX6iNVEAUYPWZuIGVECw2/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	68576.00	2200.00	0.0000	2200.00	1600.00	0.00	50000.00	75000.00	0.00	0.00	0.00	0.00	100000.00
a3497f34-9b81-411d-81d4-083e33a3b31a	Harrier	EV	Harrier EV Empowered AWDST75FC	Automatic	3023000.00	https://drive.google.com/file/d/1tTb8zpZS8PGZX6iNVEAUYPWZuIGVECw2/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	69572.00	2200.00	0.0000	2200.00	1600.00	0.00	50000.00	75000.00	0.00	0.00	0.00	0.00	100000.00
fb8a315b-a7ae-4dc0-946b-25a8695c130f	Harrier	EV	Harrier EV Empowered ST 75	Automatic	2824000.00	https://drive.google.com/file/d/1tTb8zpZS8PGZX6iNVEAUYPWZuIGVECw2/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	66927.00	2200.00	0.0000	2200.00	1600.00	0.00	50000.00	75000.00	0.00	0.00	0.00	0.00	100000.00
46f33024-69b3-4d44-aeec-48dc1c6a30b5	Harrier	EV	Harrier EV Empowered ST 75ACFC	Automatic	2873000.00	https://drive.google.com/file/d/1tTb8zpZS8PGZX6iNVEAUYPWZuIGVECw2/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	67580.00	2200.00	0.0000	2200.00	1600.00	0.00	50000.00	75000.00	0.00	0.00	0.00	0.00	100000.00
d3b45a2e-5a41-4626-8d9e-4824e0b2da5a	Harrier	EV	Harrier EV Fearless+ 65	Automatic	2399000.00	https://drive.google.com/file/d/1tTb8zpZS8PGZX6iNVEAUYPWZuIGVECw2/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	61279.00	2200.00	0.0000	2200.00	1600.00	0.00	50000.00	75000.00	0.00	0.00	0.00	0.00	100000.00
115c3a95-67e0-4e15-8d58-d4f953eec5a3	Harrier	EV	Harrier EV Fearless+ 65 ACFC	Automatic	2448000.00	https://drive.google.com/file/d/1tTb8zpZS8PGZX6iNVEAUYPWZuIGVECw2/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	61930.00	2200.00	0.0000	2200.00	1600.00	0.00	50000.00	75000.00	0.00	0.00	0.00	0.00	100000.00
cd1eec38-7aed-46dc-a118-e56c842d6c9d	Harrier	EV	Harrier EV Fearless+ 75	Automatic	2499000.00	https://drive.google.com/file/d/1tTb8zpZS8PGZX6iNVEAUYPWZuIGVECw2/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	62607.00	2200.00	0.0000	2200.00	1600.00	0.00	50000.00	75000.00	0.00	0.00	0.00	0.00	100000.00
4bdc6204-397e-44fe-9f90-12b2be37188d	Harrier	EV	Harrier EV Fearless+ 75 ACFC	Automatic	2548000.00	https://drive.google.com/file/d/1tTb8zpZS8PGZX6iNVEAUYPWZuIGVECw2/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	63259.00	2200.00	0.0000	2200.00	1600.00	0.00	50000.00	75000.00	0.00	0.00	0.00	0.00	100000.00
8c1f1a8e-36b8-402a-a4f3-fde785fc91f4	Harrier	Petrol	Harrier Adventure X AT P	Automatic	1847290.00	https://drive.google.com/file/d/1Li1FzGuVaptdcrOfOgi1Ab-wFnHsgcWa/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	57551.00	212520.00	0.0000	30692.00	160565.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
3b2b0c31-69a2-44aa-9a4c-e7b15c9cc823	Harrier	Petrol	Harrier Adventure X DK AT P	Automatic	1889990.00	https://drive.google.com/file/d/1Li1FzGuVaptdcrOfOgi1Ab-wFnHsgcWa/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	58102.00	217324.00	0.0000	31200.00	164168.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
14935d1b-cf0f-4dd9-8efb-a63ed1b01b1f	Harrier	Petrol	Harrier Adventure X DK P	Manual	1738490.00	https://drive.google.com/file/d/1Li1FzGuVaptdcrOfOgi1Ab-wFnHsgcWa/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	56148.00	200280.00	0.0000	29396.00	151385.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
2042cd05-338e-47f8-b8e0-77512b8bd026	Harrier	Petrol	Harrier Adventure X P	Manual	1686490.00	https://drive.google.com/file/d/1Li1FzGuVaptdcrOfOgi1Ab-wFnHsgcWa/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	55479.00	194430.00	0.0000	28777.00	146998.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
4cf29390-ce8b-40c9-9132-f71980645d4f	Harrier	Petrol	Harrier Adventure X+ AT P	Automatic	1874390.00	https://drive.google.com/file/d/1Li1FzGuVaptdcrOfOgi1Ab-wFnHsgcWa/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	57900.00	215569.00	0.0000	31014.00	162852.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
3c0f48f2-cfd1-4d5f-8e5f-b29c2116512d	Harrier	Petrol	Harrier Adventure X+ DK AT P	Automatic	1926390.00	https://drive.google.com/file/d/1Li1FzGuVaptdcrOfOgi1Ab-wFnHsgcWa/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	58570.00	221419.00	0.0000	31633.00	167239.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
cb6c722b-e8c3-41a3-9733-7c6da6c58640	Harrier	Petrol	Harrier Adventure X+ DK P	Manual	1765590.00	https://drive.google.com/file/d/1Li1FzGuVaptdcrOfOgi1Ab-wFnHsgcWa/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	56498.00	203329.00	0.0000	29719.00	153672.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
20755767-2174-4e99-965d-e7bf5c3d9658	Harrier	Petrol	Harrier Adventure X+ P	Manual	1713590.00	https://drive.google.com/file/d/1Li1FzGuVaptdcrOfOgi1Ab-wFnHsgcWa/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	55828.00	197479.00	0.0000	29100.00	149284.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
ec26bd2b-b959-4d5e-b16d-b13dcdcdfff2	Harrier	Petrol	Harrier Fearless UL AT P	Automatic	2413890.00	https://drive.google.com/file/d/1Li1FzGuVaptdcrOfOgi1Ab-wFnHsgcWa/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	64853.00	276263.00	0.0000	37437.00	208372.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
48773bd2-2397-4bbe-a528-2e9228cd80b0	Harrier	Petrol	Harrier Fearless UL P	Manual	2271990.00	https://drive.google.com/file/d/1Li1FzGuVaptdcrOfOgi1Ab-wFnHsgcWa/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	63024.00	260299.00	0.0000	35748.00	196399.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
c3180e92-edc3-4911-98c9-8f3c056a774f	Harrier	Petrol	Harrier Fearless UL RDK AT P	Automatic	2468890.00	https://drive.google.com/file/d/1Li1FzGuVaptdcrOfOgi1Ab-wFnHsgcWa/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	65562.00	282450.00	0.0000	38092.00	213013.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
a87fe490-48a3-454d-8787-06f439751ccb	Harrier	Petrol	Harrier Fearless UL RDK P	Manual	2326990.00	https://drive.google.com/file/d/1Li1FzGuVaptdcrOfOgi1Ab-wFnHsgcWa/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	63733.00	266486.00	0.0000	36402.00	201040.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
d628cdea-fb85-4be4-85ce-ccc3f68ed70d	Harrier	Petrol	Harrier Fearless X AT P	Automatic	2178890.00	https://drive.google.com/file/d/1Li1FzGuVaptdcrOfOgi1Ab-wFnHsgcWa/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	61825.00	249825.00	0.0000	34639.00	188544.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
b023b02c-0020-42dd-87db-320534cc99de	Harrier	Petrol	Harrier Fearless X DK AT P	Automatic	2230890.00	https://drive.google.com/file/d/1Li1FzGuVaptdcrOfOgi1Ab-wFnHsgcWa/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	62495.00	255675.00	0.0000	35258.00	192931.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
3672b46e-8dbf-49d9-b19e-ce5474b8a0d4	Harrier	Petrol	Harrier Fearless X DK P	Manual	2065390.00	https://drive.google.com/file/d/1Li1FzGuVaptdcrOfOgi1Ab-wFnHsgcWa/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	60362.00	237056.00	0.0000	33288.00	178967.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
6b5a0512-3476-45d0-a417-d9bc546ff3b2	Harrier	Petrol	Harrier Fearless X P	Manual	1999990.00	https://drive.google.com/file/d/1Li1FzGuVaptdcrOfOgi1Ab-wFnHsgcWa/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	59519.00	229699.00	0.0000	32509.00	173449.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
0f9110a7-d290-4029-a1a4-54093aa69528	Harrier	Petrol	Harrier Fearless X+ AT P	Automatic	2353890.00	https://drive.google.com/file/d/1Li1FzGuVaptdcrOfOgi1Ab-wFnHsgcWa/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	64080.00	269513.00	0.0000	36723.00	203310.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
28b9de32-e44b-4e4e-909b-adc618146ec0	Harrier	Petrol	Harrier Fearless X+ DK AT P	Automatic	2405890.00	https://drive.google.com/file/d/1Li1FzGuVaptdcrOfOgi1Ab-wFnHsgcWa/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	64750.00	275363.00	0.0000	37342.00	207697.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
5da677ec-b191-4878-975b-ec6325e6b6b5	Harrier	Petrol	Harrier Fearless X+ DK P	Manual	2263990.00	https://drive.google.com/file/d/1Li1FzGuVaptdcrOfOgi1Ab-wFnHsgcWa/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	62921.00	259399.00	0.0000	35652.00	195724.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
c85d9d41-5041-463d-b0dc-1ea91b86a10d	Harrier	Petrol	Harrier Fearless X+ P	Manual	2211990.00	https://drive.google.com/file/d/1Li1FzGuVaptdcrOfOgi1Ab-wFnHsgcWa/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	62251.00	253549.00	0.0000	35033.00	191337.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
6c0cd666-e1bb-4aee-9042-b2ce87a4617d	Harrier	Petrol	Harrier Pure X AT P	Automatic	1753190.00	https://drive.google.com/file/d/1Li1FzGuVaptdcrOfOgi1Ab-wFnHsgcWa/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	56338.00	201934.00	0.0000	29571.00	152626.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
b3ebd10d-9fa8-4fff-9e23-37356da0fbaf	Harrier	Petrol	Harrier Pure X DK AT P	Automatic	1791090.00	https://drive.google.com/file/d/1Li1FzGuVaptdcrOfOgi1Ab-wFnHsgcWa/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	56826.00	206198.00	0.0000	30023.00	155824.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
319295b3-ccb9-4c19-9a8c-74f3d5ef43a7	Harrier	Petrol	Harrier Pure X DK P	Manual	1663390.00	https://drive.google.com/file/d/1Li1FzGuVaptdcrOfOgi1Ab-wFnHsgcWa/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	55182.00	191831.00	0.0000	28502.00	145048.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
e76f02bc-029e-4c18-babf-41c02d3af4ff	Harrier	Petrol	Harrier Pure X P	Manual	1599990.00	https://drive.google.com/file/d/1Li1FzGuVaptdcrOfOgi1Ab-wFnHsgcWa/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	54364.00	184699.00	0.0000	27748.00	139699.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
74d4a577-82dc-4c3b-a700-c80c2a8a106e	Harrier	Petrol	Harrier Smart P	Manual	1289000.00	https://drive.google.com/file/d/1Li1FzGuVaptdcrOfOgi1Ab-wFnHsgcWa/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	50355.00	149713.00	0.0000	24045.00	113460.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
f4e3616a-df3d-4d76-b016-5aa9895ab226	Nexon	CNG	Nexon Creative + PS DK CNG	Manual	1253290.00	https://drive.google.com/file/d/1BMEjbdh1Ih9JQvVymiFvscBORiYWrOFL/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	31480.00	131596.00	0.0000	24632.00	99872.00	10000.00	15000.00	20000.00	5000.00	0.00	0.00	0.00	0.00
5f51fc7f-dbe3-4d56-b4b1-d92757ffa6bb	Nexon	CNG	Nexon Creative + PS DT CNG New	Manual	1216690.00	https://drive.google.com/file/d/1BMEjbdh1Ih9JQvVymiFvscBORiYWrOFL/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	31009.00	127890.00	0.0000	24166.00	97093.00	10000.00	15000.00	20000.00	5000.00	0.00	0.00	0.00	0.00
1858cb3f-d9d2-4f61-b204-c833a7216357	Nexon	CNG	Nexon Creative + S CNG New	Manual	1125190.00	https://drive.google.com/file/d/1BMEjbdh1Ih9JQvVymiFvscBORiYWrOFL/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	29833.00	118625.00	0.0000	23003.00	90144.00	10000.00	15000.00	20000.00	5000.00	0.00	0.00	0.00	0.00
240fcb56-edc7-4181-9734-070f084fd5f8	Nexon	CNG	Nexon Creative + S DK CNG New	Manual	1161790.00	https://drive.google.com/file/d/1BMEjbdh1Ih9JQvVymiFvscBORiYWrOFL/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	30304.00	122331.00	0.0000	23469.00	92923.00	10000.00	15000.00	20000.00	5000.00	0.00	0.00	0.00	0.00
79f0f16f-6f9d-4bf0-93e3-d81eb964f764	Nexon	CNG	Nexon Creative CNG New	Manual	1097790.00	https://drive.google.com/file/d/1BMEjbdh1Ih9JQvVymiFvscBORiYWrOFL/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	29481.00	115851.00	0.0000	22655.00	88063.00	10000.00	15000.00	20000.00	5000.00	0.00	0.00	0.00	0.00
f889ab95-2142-4735-beb7-07438f4c2f59	Nexon	CNG	Nexon Fearless + PS DK CNG New	Manual	1326490.00	https://drive.google.com/file/d/1BMEjbdh1Ih9JQvVymiFvscBORiYWrOFL/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	31757.00	139007.00	0.0000	25562.00	105430.00	10000.00	15000.00	20000.00	5000.00	0.00	0.00	0.00	0.00
70bc904d-a946-4d21-9e03-3382c347e96e	Nexon	CNG	Nexon Fearless + PS DT CNG New	Manual	1308190.00	https://drive.google.com/file/d/1BMEjbdh1Ih9JQvVymiFvscBORiYWrOFL/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	31527.00	137154.00	0.0000	25330.00	104041.00	10000.00	15000.00	20000.00	5000.00	0.00	0.00	0.00	0.00
29f81ae7-5ef6-4ca5-8f7f-c9cbda2c1309	Nexon	CNG	Nexon Fearless + PS RDK CNG	Manual	1336490.00	https://drive.google.com/file/d/1BMEjbdh1Ih9JQvVymiFvscBORiYWrOFL/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	31882.00	140020.00	0.0000	25689.00	106190.00	10000.00	15000.00	20000.00	5000.00	0.00	0.00	0.00	0.00
f0681001-e44f-4e8f-a8cf-120c0d3fa71e	Nexon	CNG	Nexon Pure + CNG	Manual	978890.00	https://drive.google.com/file/d/1BMEjbdh1Ih9JQvVymiFvscBORiYWrOFL/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	27952.00	103813.00	0.0000	21144.00	79035.00	10000.00	15000.00	20000.00	5000.00	0.00	0.00	0.00	0.00
310d815c-62be-4f84-863f-c3f9e02cbfac	Nexon	CNG	Nexon Pure + S CNG	Manual	999990.00	https://drive.google.com/file/d/1BMEjbdh1Ih9JQvVymiFvscBORiYWrOFL/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	28223.00	105949.00	0.0000	21412.00	80637.00	10000.00	15000.00	20000.00	5000.00	0.00	0.00	0.00	0.00
c1a3eae4-d9c2-49f1-b77f-0b9a0c7b996a	Nexon	CNG	Nexon Smart + CNG	Manual	914890.00	https://drive.google.com/file/d/1BMEjbdh1Ih9JQvVymiFvscBORiYWrOFL/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	27129.00	97333.00	0.0000	20330.00	74175.00	10000.00	15000.00	20000.00	5000.00	0.00	0.00	0.00	0.00
161dd3f5-7a7a-44c3-b7fe-d58ec725fc0b	Nexon	CNG	Nexon Smart + S CNG	Manual	942290.00	https://drive.google.com/file/d/1BMEjbdh1Ih9JQvVymiFvscBORiYWrOFL/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	27481.00	100107.00	0.0000	20678.00	76255.00	10000.00	15000.00	20000.00	5000.00	0.00	0.00	0.00	0.00
0cd66f31-aa58-4059-94cb-2283a0b729a4	Nexon	CNG	Nexon Smart CNG	Manual	823390.00	https://drive.google.com/file/d/1BMEjbdh1Ih9JQvVymiFvscBORiYWrOFL/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	25952.00	88068.00	0.0000	19167.00	67226.00	10000.00	15000.00	20000.00	5000.00	0.00	0.00	0.00	0.00
da21537c-997a-401f-b1fc-c6068de1049d	Nexon	Diesel	Nexon Creative + PS AMT DK 1.5	Automatic	1333290.00	https://drive.google.com/file/d/1BMEjbdh1Ih9JQvVymiFvscBORiYWrOFL/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	31843.00	184694.00	0.0000	31298.00	139696.00	10000.00	15000.00	40000.00	5000.00	0.00	0.00	0.00	0.00
c33dc8ad-bbae-4bc0-ae8d-8b9bdefb74d6	Nexon	Diesel	Nexon Creative + PS AMT DT 1.5	Automatic	1297190.00	https://drive.google.com/file/d/1BMEjbdh1Ih9JQvVymiFvscBORiYWrOFL/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	31390.00	179821.00	0.0000	30686.00	136041.00	10000.00	15000.00	40000.00	5000.00	0.00	0.00	0.00	0.00
e18f2af6-1887-4d06-8b54-41cdb7f14cc8	Nexon	Diesel	Nexon Creative + PS DK 1.5	Manual	1270190.00	https://drive.google.com/file/d/1BMEjbdh1Ih9JQvVymiFvscBORiYWrOFL/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	31052.00	176176.00	0.0000	30229.00	133307.00	10000.00	15000.00	40000.00	5000.00	0.00	0.00	0.00	0.00
5ef98336-5dd9-48e8-8597-9de42f6691cd	Nexon	Diesel	Nexon Creative + PS DT 1.5	Manual	1234190.00	https://drive.google.com/file/d/1BMEjbdh1Ih9JQvVymiFvscBORiYWrOFL/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	30601.00	171316.00	0.0000	29618.00	129662.00	10000.00	15000.00	40000.00	5000.00	0.00	0.00	0.00	0.00
af9e7153-c735-4e2e-a088-bb773d7f8ad5	Nexon	Diesel	Nexon Creative + S 1.5 New	Manual	1144090.00	https://drive.google.com/file/d/1BMEjbdh1Ih9JQvVymiFvscBORiYWrOFL/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	29474.00	159152.00	0.0000	28091.00	120539.00	10000.00	15000.00	40000.00	5000.00	0.00	0.00	0.00	0.00
84a21136-5fba-4e24-9f14-9722cb2eb2eb	Nexon	Diesel	Nexon Creative + S AMT 1.5 New	Automatic	1207090.00	https://drive.google.com/file/d/1BMEjbdh1Ih9JQvVymiFvscBORiYWrOFL/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	30262.00	167657.00	0.0000	29159.00	126918.00	10000.00	15000.00	40000.00	5000.00	0.00	0.00	0.00	0.00
2a650706-c551-4699-8ea1-73f3eb719bcd	Nexon	Diesel	Nexon Creative + S DK 1.5 New	Manual	1180090.00	https://drive.google.com/file/d/1BMEjbdh1Ih9JQvVymiFvscBORiYWrOFL/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	29924.00	164012.00	0.0000	28702.00	124184.00	10000.00	15000.00	40000.00	5000.00	0.00	0.00	0.00	0.00
50daf1e7-0670-4dfd-9081-c013d662ce4c	Nexon	Diesel	Nexon Creative 1.5 New	Manual	1117090.00	https://drive.google.com/file/d/1BMEjbdh1Ih9JQvVymiFvscBORiYWrOFL/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	29135.00	155507.00	0.0000	27634.00	117805.00	10000.00	15000.00	40000.00	5000.00	0.00	0.00	0.00	0.00
c1b88261-e11a-4e11-9b53-f82c9c04cbde	Nexon	Diesel	Nexon Creative AMT 1.5 New	Automatic	1180090.00	https://drive.google.com/file/d/1BMEjbdh1Ih9JQvVymiFvscBORiYWrOFL/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	29924.00	164012.00	0.0000	28702.00	124184.00	10000.00	15000.00	40000.00	5000.00	0.00	0.00	0.00	0.00
1bfd35c6-4fac-43be-a3a5-bdb12ea35889	Nexon	Diesel	Nexon Creative+S AMT DK1.5 New	Automatic	1243190.00	https://drive.google.com/file/d/1BMEjbdh1Ih9JQvVymiFvscBORiYWrOFL/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	30714.00	172531.00	0.0000	29771.00	130573.00	10000.00	15000.00	40000.00	5000.00	0.00	0.00	0.00	0.00
f97b58da-fc71-4f28-aacc-4b39db3788b2	Nexon	Diesel	Nexon Fearless + PS DK 1.5 New	Manual	1342290.00	https://drive.google.com/file/d/1BMEjbdh1Ih9JQvVymiFvscBORiYWrOFL/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	31956.00	185909.00	0.0000	31451.00	140607.00	10000.00	15000.00	40000.00	5000.00	0.00	0.00	0.00	0.00
ad9e0c64-8fd1-4751-9d93-30d889d28a87	Nexon	Diesel	Nexon Fearless + PS DT 1.5 New	Manual	1324190.00	https://drive.google.com/file/d/1BMEjbdh1Ih9JQvVymiFvscBORiYWrOFL/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	31729.00	183466.00	0.0000	31144.00	138775.00	10000.00	15000.00	40000.00	5000.00	0.00	0.00	0.00	0.00
a561700e-6893-400b-af38-39e092a7f77e	Nexon	Diesel	Nexon Fearless + S DT 1.5	Manual	1324113.00	https://drive.google.com/file/d/1BMEjbdh1Ih9JQvVymiFvscBORiYWrOFL/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	31728.00	183456.00	0.0000	31143.00	138767.00	10000.00	15000.00	40000.00	5000.00	0.00	0.00	0.00	0.00
073b19b5-e63f-426e-be10-ebe109a24eac	Nexon	Diesel	Nexon Fearless+PS AMT DK1.5New	Automatic	1405290.00	https://drive.google.com/file/d/1BMEjbdh1Ih9JQvVymiFvscBORiYWrOFL/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	32744.00	194414.00	0.0000	32518.00	146986.00	10000.00	15000.00	40000.00	5000.00	0.00	0.00	0.00	0.00
d9e61be2-71e4-42f0-bdd8-ba09f1a96def	Nexon	Diesel	Nexon Fearless+PS AMT DT1.5New	Automatic	1387290.00	https://drive.google.com/file/d/1BMEjbdh1Ih9JQvVymiFvscBORiYWrOFL/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	32518.00	191984.00	0.0000	32213.00	145163.00	10000.00	15000.00	40000.00	5000.00	0.00	0.00	0.00	0.00
b09482c2-42a5-4caf-b6cf-84743da92ece	Nexon	Diesel	Nexon Fearless+PS AMT RDK 1.5	Automatic	1415290.00	https://drive.google.com/file/d/1BMEjbdh1Ih9JQvVymiFvscBORiYWrOFL/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	32869.00	195764.00	0.0000	32688.00	147998.00	10000.00	15000.00	40000.00	5000.00	0.00	0.00	0.00	0.00
c4fc1914-3223-412e-80da-39b995e69b92	Nexon	Diesel	Nexon Fearless+PS RDK 1.5	Manual	1352290.00	https://drive.google.com/file/d/1BMEjbdh1Ih9JQvVymiFvscBORiYWrOFL/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	32081.00	187259.00	0.0000	31620.00	141619.00	10000.00	15000.00	40000.00	5000.00	0.00	0.00	0.00	0.00
61cb228c-1824-4860-9ee7-6016785f51d0	Nexon	Diesel	Nexon Pure + 1.5	Manual	990990.00	https://drive.google.com/file/d/1BMEjbdh1Ih9JQvVymiFvscBORiYWrOFL/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	27557.00	138484.00	0.0000	25496.00	105038.00	10000.00	15000.00	40000.00	5000.00	0.00	0.00	0.00	0.00
677ce266-7a68-47a0-849e-37f0f10d00ee	Nexon	Diesel	Nexon Pure + AMT 1.5	Automatic	1053990.00	https://drive.google.com/file/d/1BMEjbdh1Ih9JQvVymiFvscBORiYWrOFL/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	28346.00	146989.00	0.0000	26564.00	111417.00	10000.00	15000.00	40000.00	5000.00	0.00	0.00	0.00	0.00
af791949-30e4-47b3-858a-827f2f74df63	Nexon	Diesel	Nexon Pure + S 1.5	Manual	1017990.00	https://drive.google.com/file/d/1BMEjbdh1Ih9JQvVymiFvscBORiYWrOFL/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	27895.00	142129.00	0.0000	25954.00	107772.00	10000.00	15000.00	40000.00	5000.00	0.00	0.00	0.00	0.00
9471f092-c884-4c38-8fd6-98390af81d9f	Nexon	Diesel	Nexon Smart + 1.5	Manual	900890.00	https://drive.google.com/file/d/1BMEjbdh1Ih9JQvVymiFvscBORiYWrOFL/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	26430.00	126320.00	0.0000	23969.00	95915.00	10000.00	15000.00	40000.00	5000.00	0.00	0.00	0.00	0.00
1686f57d-a6ab-45a1-8138-7efb2b126547	Nexon	Diesel	Nexon Smart + S 1.5	Manual	927890.00	https://drive.google.com/file/d/1BMEjbdh1Ih9JQvVymiFvscBORiYWrOFL/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	26767.00	129965.00	0.0000	24427.00	98649.00	10000.00	15000.00	40000.00	5000.00	0.00	0.00	0.00	0.00
c11fa32c-ef9e-40da-865a-77c422b76ff6	Nexon	EV	Nexon EV 3.0 Creative + MR	Automatic	1249000.00	https://drive.google.com/file/d/1H9Gj6f1wNmuT1QVM8qJw1k_QmETGCYKI/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	46964.00	2200.00	0.0000	2200.00	1600.00	0.00	30000.00	35000.00	0.00	0.00	10000.00	10000.00	20000.00
a2dbfe4c-d301-4702-88fb-3b3667757d36	Nexon	EV	Nexon EV 3.0 Creative 45	Automatic	1399000.00	https://drive.google.com/file/d/1H9Gj6f1wNmuT1QVM8qJw1k_QmETGCYKI/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	49075.00	2200.00	0.0000	2200.00	1600.00	0.00	30000.00	35000.00	0.00	0.00	10000.00	10000.00	20000.00
009a429a-3f49-4a58-a624-92f73ff88dda	Nexon	EV	Nexon EV 3.0 Empowered 45	Automatic	1599000.00	https://drive.google.com/file/d/1H9Gj6f1wNmuT1QVM8qJw1k_QmETGCYKI/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	51888.00	2200.00	0.0000	2200.00	1600.00	0.00	30000.00	35000.00	0.00	0.00	10000.00	10000.00	20000.00
22d4d8d2-6804-4ddb-91d2-4b11dcbb2338	Nexon	EV	Nexon EV 3.0 Empowered+A 45	Automatic	1729000.00	https://drive.google.com/file/d/1H9Gj6f1wNmuT1QVM8qJw1k_QmETGCYKI/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	53718.00	2200.00	0.0000	2200.00	1600.00	0.00	30000.00	35000.00	0.00	0.00	10000.00	10000.00	20000.00
c8ecbae6-5219-4601-ad4a-48297a6c93bf	Nexon	EV	Nexon EV 3.0 Empowered+A 45 DK	Automatic	1749000.00	https://drive.google.com/file/d/1H9Gj6f1wNmuT1QVM8qJw1k_QmETGCYKI/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	53998.00	2200.00	0.0000	2200.00	1600.00	0.00	30000.00	35000.00	0.00	0.00	10000.00	10000.00	20000.00
671eaa91-9514-478a-9485-6c2c95350064	Nexon	EV	Nexon EV 3.0 Empowered+A 45RDK	Automatic	1749000.00	https://drive.google.com/file/d/1H9Gj6f1wNmuT1QVM8qJw1k_QmETGCYKI/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	53998.00	2200.00	0.0000	2200.00	1600.00	0.00	30000.00	35000.00	0.00	0.00	10000.00	10000.00	20000.00
72adc7c7-bd55-4a48-a86b-8f4ea1fa9481	Nexon	EV	Nexon EV 3.0 Fearless 45	Automatic	1499000.00	https://drive.google.com/file/d/1H9Gj6f1wNmuT1QVM8qJw1k_QmETGCYKI/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	50480.00	2200.00	0.0000	2200.00	1600.00	0.00	30000.00	35000.00	0.00	0.00	10000.00	10000.00	20000.00
892bece1-5714-46d3-9173-0732603255b6	Nexon	EV	Nexon EV 3.0 Fearless MR	Automatic	1329000.00	https://drive.google.com/file/d/1H9Gj6f1wNmuT1QVM8qJw1k_QmETGCYKI/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	48090.00	2200.00	0.0000	2200.00	1600.00	0.00	30000.00	35000.00	0.00	0.00	10000.00	10000.00	20000.00
0f3cd8f9-29a1-40f9-abf7-147d0aec4455	Nexon	Petrol	Nexon Creative + PS DCA DK 1.2	DCA	1271590.00	https://drive.google.com/file/d/1BMEjbdh1Ih9JQvVymiFvscBORiYWrOFL/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	31071.00	133448.00	0.0000	24864.00	101261.00	10000.00	15000.00	30000.00	5000.00	10000.00	0.00	0.00	0.00
9f9c0842-16b1-4b24-98f7-b6411e12bb69	Nexon	Petrol	Nexon Creative + PS DCA DT 1.2	DCA	1234990.00	https://drive.google.com/file/d/1BMEjbdh1Ih9JQvVymiFvscBORiYWrOFL/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	30613.00	129743.00	0.0000	24399.00	98482.00	10000.00	15000.00	30000.00	5000.00	10000.00	0.00	0.00	0.00
8ae8981d-fa7a-4cda-adbc-02da8d0b69f4	Nexon	Petrol	Nexon Creative + PS DK 1.2	Manual	1161790.00	https://drive.google.com/file/d/1BMEjbdh1Ih9JQvVymiFvscBORiYWrOFL/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	29696.00	122331.00	0.0000	23469.00	92923.00	10000.00	15000.00	30000.00	5000.00	10000.00	0.00	0.00	0.00
81604dc3-792c-4091-96db-f937d2511da4	Nexon	Petrol	Nexon Creative + PS DT 1.2	Manual	1125190.00	https://drive.google.com/file/d/1BMEjbdh1Ih9JQvVymiFvscBORiYWrOFL/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	29237.00	118625.00	0.0000	23003.00	90144.00	10000.00	15000.00	30000.00	5000.00	10000.00	0.00	0.00	0.00
edd6bd5b-a7f9-4dee-b7b1-7a38e16811bb	Nexon	Petrol	Nexon Creative + S 1.2 New	Manual	1033790.00	https://drive.google.com/file/d/1BMEjbdh1Ih9JQvVymiFvscBORiYWrOFL/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	28093.00	109371.00	0.0000	21841.00	83203.00	10000.00	15000.00	30000.00	5000.00	10000.00	0.00	0.00	0.00
ba5a85ed-007b-4198-b046-56f3d0f2f373	Nexon	Petrol	Nexon Creative + S AMT 1.2 New	Automatic	1097790.00	https://drive.google.com/file/d/1BMEjbdh1Ih9JQvVymiFvscBORiYWrOFL/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	28895.00	115851.00	0.0000	22655.00	88063.00	10000.00	15000.00	30000.00	5000.00	10000.00	0.00	0.00	0.00
f00289f3-fb8c-4b94-909e-e59d6a1100b4	Nexon	Petrol	Nexon Creative + S DK 1.2 New	Manual	1070390.00	https://drive.google.com/file/d/1BMEjbdh1Ih9JQvVymiFvscBORiYWrOFL/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	28551.00	113077.00	0.0000	22307.00	85983.00	10000.00	15000.00	30000.00	5000.00	10000.00	0.00	0.00	0.00
ee72868d-9a1f-4b6a-9af2-c461a1e65fb9	Nexon	Petrol	Nexon Creative 1.2 New	Manual	999990.00	https://drive.google.com/file/d/1BMEjbdh1Ih9JQvVymiFvscBORiYWrOFL/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	27670.00	105949.00	0.0000	21412.00	80637.00	10000.00	15000.00	30000.00	5000.00	10000.00	0.00	0.00	0.00
12e71d4d-8358-4ed5-882f-b8cde3ad78e8	Nexon	Petrol	Nexon Creative AMT 1.2 New	Automatic	1070390.00	https://drive.google.com/file/d/1BMEjbdh1Ih9JQvVymiFvscBORiYWrOFL/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	28551.00	113077.00	0.0000	22307.00	85983.00	10000.00	15000.00	30000.00	5000.00	10000.00	0.00	0.00	0.00
61395a1a-4e4a-44ab-94b2-00c74473abca	Nexon	Petrol	Nexon Creative DCA 1.2 New	DCA	1116090.00	https://drive.google.com/file/d/1BMEjbdh1Ih9JQvVymiFvscBORiYWrOFL/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	29122.00	117704.00	0.0000	22888.00	89453.00	10000.00	15000.00	30000.00	5000.00	10000.00	0.00	0.00	0.00
05b309fe-7218-475f-afb8-12d5fba12e22	Nexon	Petrol	Nexon Creative+S AMT DK1.2 New	Automatic	1134390.00	https://drive.google.com/file/d/1BMEjbdh1Ih9JQvVymiFvscBORiYWrOFL/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	29353.00	119557.00	0.0000	23120.00	90843.00	10000.00	15000.00	30000.00	5000.00	10000.00	0.00	0.00	0.00
5e01a6ee-6bfb-4b8f-8174-e0f6c00c587e	Nexon	Petrol	Nexon Fearless + DCA DT 1.2	DCA	1308053.00	https://drive.google.com/file/d/1BMEjbdh1Ih9JQvVymiFvscBORiYWrOFL/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	31526.00	137141.00	0.0000	25328.00	104031.00	10000.00	15000.00	30000.00	5000.00	10000.00	0.00	0.00	0.00
fe238466-5ef9-465f-bd8b-902f7b02aaef	Nexon	Petrol	Nexon Fearless + PS DK 1.2 New	Manual	1234990.00	https://drive.google.com/file/d/1BMEjbdh1Ih9JQvVymiFvscBORiYWrOFL/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	30613.00	129743.00	0.0000	24399.00	98482.00	10000.00	15000.00	30000.00	5000.00	10000.00	0.00	0.00	0.00
88061cc8-3e54-44a7-b78a-417a4cf5f49b	Nexon	Petrol	Nexon Fearless + PS DT 1.2 New	Manual	1216690.00	https://drive.google.com/file/d/1BMEjbdh1Ih9JQvVymiFvscBORiYWrOFL/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	30383.00	127890.00	0.0000	24166.00	97093.00	10000.00	15000.00	30000.00	5000.00	10000.00	0.00	0.00	0.00
b9646bf5-6010-4c33-a4c5-afcfc8ca7da1	Nexon	Petrol	Nexon Fearless S DT 1.2	Manual	1198285.00	https://drive.google.com/file/d/1BMEjbdh1Ih9JQvVymiFvscBORiYWrOFL/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	30151.00	126027.00	0.0000	23932.00	95695.00	10000.00	15000.00	30000.00	5000.00	10000.00	0.00	0.00	0.00
8ee50bf5-8a45-45e3-8bda-59f4da86e19e	Nexon	Petrol	Nexon Fearless+ A PS DCA DK1.2	DCA	1371790.00	https://drive.google.com/file/d/1BMEjbdh1Ih9JQvVymiFvscBORiYWrOFL/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	32324.00	143594.00	0.0000	26138.00	108871.00	10000.00	15000.00	30000.00	5000.00	10000.00	0.00	0.00	0.00
61c50b9a-a86b-41af-a0ed-ec07fdfddad8	Nexon	Petrol	Nexon Fearless+(A) PS DCA 1.2	DCA	1353490.00	https://drive.google.com/file/d/1BMEjbdh1Ih9JQvVymiFvscBORiYWrOFL/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	32096.00	141741.00	0.0000	25905.00	107481.00	10000.00	15000.00	30000.00	5000.00	10000.00	0.00	0.00	0.00
d0f9868a-89fc-4b5c-a054-075fcecf4e5e	Nexon	Petrol	Nexon Fearless+A PS DCA RDK1.2	DCA	1381790.00	https://drive.google.com/file/d/1BMEjbdh1Ih9JQvVymiFvscBORiYWrOFL/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	32450.00	144606.00	0.0000	26265.00	109630.00	10000.00	15000.00	30000.00	5000.00	10000.00	0.00	0.00	0.00
bfa65dfd-13f9-41ff-9a86-47a542ad4659	Nexon	Petrol	Nexon Fearless+PS DCA DK1.2New	DCA	1344790.00	https://drive.google.com/file/d/1BMEjbdh1Ih9JQvVymiFvscBORiYWrOFL/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	31986.00	140860.00	0.0000	25795.00	106820.00	10000.00	15000.00	30000.00	5000.00	10000.00	0.00	0.00	0.00
1ecc81bf-d00b-4ab8-82fb-d3e3505a53cf	Nexon	Petrol	Nexon Fearless+PS DCA DT1.2New	DCA	1326490.00	https://drive.google.com/file/d/1BMEjbdh1Ih9JQvVymiFvscBORiYWrOFL/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	31757.00	139007.00	0.0000	25562.00	105430.00	10000.00	15000.00	30000.00	5000.00	10000.00	0.00	0.00	0.00
0fded7cd-23ce-4df8-ba03-90e3c22731a6	Nexon	Petrol	Nexon Fearless+PS RDK 1.2	Manual	1244990.00	https://drive.google.com/file/d/1BMEjbdh1Ih9JQvVymiFvscBORiYWrOFL/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	30737.00	130755.00	0.0000	24526.00	99241.00	10000.00	15000.00	30000.00	5000.00	10000.00	0.00	0.00	0.00
9d89c22a-7063-4a42-9373-faee6e140a6a	Nexon	Petrol	Nexon Pure + 1.2	Manual	887390.00	https://drive.google.com/file/d/1BMEjbdh1Ih9JQvVymiFvscBORiYWrOFL/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	26260.00	94548.00	0.0000	19980.00	72086.00	10000.00	15000.00	30000.00	5000.00	10000.00	0.00	0.00	0.00
fe0e9cf0-5a1a-4eec-9526-68fefa1ab0cd	Nexon	Petrol	Nexon Pure + AMT 1.2	Automatic	951390.00	https://drive.google.com/file/d/1BMEjbdh1Ih9JQvVymiFvscBORiYWrOFL/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	27061.00	101028.00	0.0000	20794.00	76946.00	10000.00	15000.00	30000.00	5000.00	10000.00	0.00	0.00	0.00
f71dd714-ed6c-47d5-af54-c9bb7286acfa	Nexon	Petrol	Nexon Pure + S 1.2	Manual	914890.00	https://drive.google.com/file/d/1BMEjbdh1Ih9JQvVymiFvscBORiYWrOFL/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	26605.00	97333.00	0.0000	20330.00	74175.00	10000.00	15000.00	30000.00	5000.00	10000.00	0.00	0.00	0.00
7501e7c2-6811-41ca-b895-e8ed11cfe19f	Nexon	Petrol	Nexon Pure + S AMT 1.2	Automatic	978890.00	https://drive.google.com/file/d/1BMEjbdh1Ih9JQvVymiFvscBORiYWrOFL/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	27407.00	103813.00	0.0000	21144.00	79035.00	10000.00	15000.00	30000.00	5000.00	10000.00	0.00	0.00	0.00
a3a71a36-9dc2-4b9a-9b3c-a84298ceb579	Nexon	Petrol	Nexon Smart + 1.2	Manual	799990.00	https://drive.google.com/file/d/1BMEjbdh1Ih9JQvVymiFvscBORiYWrOFL/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	25166.00	85699.00	0.0000	18869.00	65449.00	10000.00	15000.00	30000.00	5000.00	10000.00	0.00	0.00	0.00
f097bef8-5386-4c7f-baf9-09284f7039e3	Nexon	Petrol	Nexon Smart + AMT 1.2	Automatic	878290.00	https://drive.google.com/file/d/1BMEjbdh1Ih9JQvVymiFvscBORiYWrOFL/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	26146.00	93627.00	0.0000	19865.00	71395.00	10000.00	15000.00	30000.00	5000.00	10000.00	0.00	0.00	0.00
ae451b57-3e77-43dd-8d5b-98aaaa83423a	Nexon	Petrol	Nexon Smart + S 1.2	Manual	829990.00	https://drive.google.com/file/d/1BMEjbdh1Ih9JQvVymiFvscBORiYWrOFL/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	25541.00	88736.00	0.0000	19251.00	67727.00	10000.00	15000.00	30000.00	5000.00	10000.00	0.00	0.00	0.00
46588e56-fb78-44a0-93a0-dd8de7810f71	Nexon	Petrol	Nexon Smart 1.2	Manual	731890.00	https://drive.google.com/file/d/1BMEjbdh1Ih9JQvVymiFvscBORiYWrOFL/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	24314.00	78804.00	0.0000	18004.00	60278.00	10000.00	15000.00	30000.00	5000.00	10000.00	0.00	0.00	0.00
2ada4d5c-07b1-405a-acc4-c47006f2409e	Punch2.0	CNG	Punch2.0 Accomplished CNG	Manual	929900.00	https://drive.google.com/file/d/1bECcjh4vFr1vWV5ZDDqG848IvYsdvnbr/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	26837.00	98852.00	0.0000	20521.00	75314.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
56abb619-8e5f-426c-9642-421a8ba5dcbc	Punch2.0	CNG	Punch2.0 Accomplished+S CNGAMT	Automatic	1054900.00	https://drive.google.com/file/d/1bECcjh4vFr1vWV5ZDDqG848IvYsdvnbr/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	26511.00	111509.00	0.0000	22110.00	84807.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
9aeb8e6a-e2a9-430a-8a1a-d6cef5dfcba1	Punch2.0	CNG	Punch2.0 Adventure CNG	Manual	859900.00	https://drive.google.com/file/d/1bECcjh4vFr1vWV5ZDDqG848IvYsdvnbr/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	25958.00	91765.00	0.0000	19631.00	69999.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
6614dd62-be49-4127-b85d-9c5661912a8f	Punch2.0	CNG	Punch2.0 Adventure CNG AMT	Automatic	914900.00	https://drive.google.com/file/d/1bECcjh4vFr1vWV5ZDDqG848IvYsdvnbr/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	25004.00	97334.00	0.0000	20330.00	74176.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
8fd12422-3c3f-467b-af46-77806d569d73	Punch2.0	CNG	Punch2.0 Adventure S CNG	Manual	894900.00	https://drive.google.com/file/d/1bECcjh4vFr1vWV5ZDDqG848IvYsdvnbr/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	26398.00	95309.00	0.0000	20076.00	72657.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
5bab201a-f3e6-46a5-a758-d7906d7cd6d7	Punch2.0	CNG	Punch2.0 Adventure S CNG AMT	Automatic	949900.00	https://drive.google.com/file/d/1bECcjh4vFr1vWV5ZDDqG848IvYsdvnbr/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	25381.00	100877.00	0.0000	20775.00	76833.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
23d613e7-3a67-4f36-8698-cd094a5892d5	Punch2.0	CNG	Punch2.0 Pure CNG	Manual	749900.00	https://drive.google.com/file/d/1bECcjh4vFr1vWV5ZDDqG848IvYsdvnbr/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	24576.00	80627.00	0.0000	18233.00	61645.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
3cb29a51-65c4-4c70-a404-43395ceab987	Punch2.0	CNG	Punch2.0 Pure+ CNG	Manual	799900.00	https://drive.google.com/file/d/1bECcjh4vFr1vWV5ZDDqG848IvYsdvnbr/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	25204.00	85690.00	0.0000	18868.00	65443.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
ed5696b4-1e69-4a5f-b446-4341d23465a8	Punch2.0	CNG	Punch2.0 Pure+ CNG AMT	Automatic	854900.00	https://drive.google.com/file/d/1bECcjh4vFr1vWV5ZDDqG848IvYsdvnbr/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	24358.00	91259.00	0.0000	19567.00	69619.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
93c8b990-48d9-4e6b-acbf-93d1e447fd7c	Punch2.0	CNG	Punch2.0 Pure+S CNG	Manual	834900.00	https://drive.google.com/file/d/1bECcjh4vFr1vWV5ZDDqG848IvYsdvnbr/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	25643.00	89234.00	0.0000	19313.00	68101.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
72d4c412-ebde-4477-b49c-0aa7e90b557d	Punch2.0	CNG	Punch2.0 Smart CNG	Manual	669900.00	https://drive.google.com/file/d/1bECcjh4vFr1vWV5ZDDqG848IvYsdvnbr/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	23569.00	72527.00	0.0000	17216.00	55570.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
2f741b94-1a4b-4911-a913-2ff74bccd482	Punch2.0	EV	Punch EV 2.0 Adventure 40	Automatic	1159000.00	https://drive.google.com/file/d/1KalyKmqoWjgZyAhwc75XDXsPdGtIFEbX/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	44189.00	2200.00	0.0000	2200.00	2200.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
9f20834c-0c91-4138-b364-235c9cd6cbce	Punch2.0	EV	Punch EV 2.0 Empowered 40	Automatic	1229000.00	https://drive.google.com/file/d/1KalyKmqoWjgZyAhwc75XDXsPdGtIFEbX/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	45815.00	2200.00	0.0000	2200.00	2200.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
b026f25e-b1b9-404a-87d8-0cf6291d4412	Punch2.0	EV	Punch EV 2.0 Empowered+ S 40	Automatic	1259000.00	https://drive.google.com/file/d/1KalyKmqoWjgZyAhwc75XDXsPdGtIFEbX/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	46511.00	2200.00	0.0000	2200.00	2200.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
54177585-4a50-4d71-90f8-9998a4d54541	Punch2.0	EV	Punch EV 2.0 Smart 30	Automatic	969000.00	https://drive.google.com/file/d/1KalyKmqoWjgZyAhwc75XDXsPdGtIFEbX/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	39777.00	2200.00	0.0000	2200.00	2200.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
7b6ce9c4-06ad-47ba-b104-1dcc5477c866	Punch2.0	EV	Punch EV 2.0 Smart+ 30	Automatic	1029000.00	https://drive.google.com/file/d/1KalyKmqoWjgZyAhwc75XDXsPdGtIFEbX/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	41170.00	2200.00	0.0000	2200.00	2200.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
c99420d8-89fb-469d-a92b-f6e550739a02	Punch2.0	EV	Punch EV 2.0 Smart+ 40	Automatic	1089000.00	https://drive.google.com/file/d/1KalyKmqoWjgZyAhwc75XDXsPdGtIFEbX/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	42563.00	2200.00	0.0000	2200.00	2200.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
fb9e0a5c-3aa6-4eaa-9cc4-e873ff644892	Punch2.0	Petrol	Punch2.0 Accomplished	Manual	829900.00	https://drive.google.com/file/d/1bECcjh4vFr1vWV5ZDDqG848IvYsdvnbr/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	25580.00	88727.00	0.0000	19250.00	67720.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
92808bb1-4dee-4a24-bfc8-3dd9ce937350	Punch2.0	Petrol	Punch2.0 Accomplished AMT	Automatic	884900.00	https://drive.google.com/file/d/1bECcjh4vFr1vWV5ZDDqG848IvYsdvnbr/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	26272.00	94296.00	0.0000	19949.00	71897.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
5b6b5d00-f7a1-412a-ad1b-f233579b2d95	Punch2.0	Petrol	Punch2.0 Accomplished+S	Manual	899900.00	https://drive.google.com/file/d/1bECcjh4vFr1vWV5ZDDqG848IvYsdvnbr/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	26460.00	95815.00	0.0000	20139.00	73036.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
92964cc3-2320-4bbf-9326-fe0b63d02dc7	Punch2.0	Petrol	Punch2.0 Accomplished+S AMT	Automatic	954900.00	https://drive.google.com/file/d/1bECcjh4vFr1vWV5ZDDqG848IvYsdvnbr/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	27152.00	101384.00	0.0000	20839.00	77213.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
eb3e8351-1497-4b8d-81fe-255329c396ae	Punch2.0	Petrol	Punch2.0 Accomplished+S TC	Manual	979900.00	https://drive.google.com/file/d/1bECcjh4vFr1vWV5ZDDqG848IvYsdvnbr/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	25704.00	103915.00	0.0000	21156.00	79111.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
2d06809e-0f52-463a-a997-c5aa8c064d95	Punch2.0	Petrol	Punch2.0 Adventure	Manual	759900.00	https://drive.google.com/file/d/1bECcjh4vFr1vWV5ZDDqG848IvYsdvnbr/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	24701.00	81640.00	0.0000	18360.00	62405.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
d395c067-aa8f-4c2a-8ff8-1d673d6b5200	Punch2.0	Petrol	Punch2.0 Adventure AMT	Automatic	814900.00	https://drive.google.com/file/d/1bECcjh4vFr1vWV5ZDDqG848IvYsdvnbr/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	25392.00	87209.00	0.0000	19059.00	66582.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
796a2aa1-4065-43e1-ae51-3fe931b369cf	Punch2.0	Petrol	Punch2.0 Adventure S	Manual	794900.00	https://drive.google.com/file/d/1bECcjh4vFr1vWV5ZDDqG848IvYsdvnbr/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	25141.00	85184.00	0.0000	18805.00	65063.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
cd927025-0f26-467d-87a4-35e7bf7660da	Punch2.0	Petrol	Punch2.0 Adventure TC	Manual	829900.00	https://drive.google.com/file/d/1bECcjh4vFr1vWV5ZDDqG848IvYsdvnbr/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	24089.00	88727.00	0.0000	19250.00	67720.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
132baf40-0cf5-40b1-b0db-9a4103c58e49	Punch2.0	Petrol	Punch2.0 Pure	Manual	649900.00	https://drive.google.com/file/d/1bECcjh4vFr1vWV5ZDDqG848IvYsdvnbr/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	23319.00	70502.00	0.0000	16961.00	54052.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
1801329b-62fb-4edd-9bde-e321806dd850	Punch2.0	Petrol	Punch2.0 Pure+	Manual	699900.00	https://drive.google.com/file/d/1bECcjh4vFr1vWV5ZDDqG848IvYsdvnbr/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	23947.00	75565.00	0.0000	17597.00	57849.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
d45323fc-c80f-49a2-bce4-77f0fee6174d	Punch2.0	Petrol	Punch2.0 Pure+ AMT	Automatic	754900.00	https://drive.google.com/file/d/1bECcjh4vFr1vWV5ZDDqG848IvYsdvnbr/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	24638.00	81134.00	0.0000	18296.00	62026.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
2748bcce-ed71-4ee8-ba71-b70b7b500f03	Punch2.0	Petrol	Punch2.0 Pure+S	Manual	734900.00	https://drive.google.com/file/d/1bECcjh4vFr1vWV5ZDDqG848IvYsdvnbr/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	24386.00	79109.00	0.0000	18042.00	60507.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
e43abecc-89bb-4c43-812d-9160f459786c	Punch2.0	Petrol	Punch2.0 Pure+S AMT	Automatic	789900.00	https://drive.google.com/file/d/1bECcjh4vFr1vWV5ZDDqG848IvYsdvnbr/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	25079.00	84677.00	0.0000	18741.00	64683.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
2d7db147-9802-48bf-807c-77012dfeac27	Punch2.0	Petrol	Punch2.0 Smart	Manual	559900.00	https://drive.google.com/file/d/1bECcjh4vFr1vWV5ZDDqG848IvYsdvnbr/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	22188.00	61390.00	0.0000	15817.00	47218.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
39eeddeb-7163-4258-a56e-056b45874345	Safari	Diesel	Safari Accomplished + DK (AT)	Manual	2544585.00	https://drive.google.com/file/d/1SJtPtL0blWJxrRM4bG5SMtK_3zWttGyF/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	66538.00	349219.00	0.0000	46051.00	263339.00	10000.00	25000.00	70000.00	8000.00	20000.00	0.00	0.00	0.00
62f580ac-7c9d-4b31-bdf4-b058ab3b9899	Safari	Diesel	Safari Accomplished X	Manual	2184290.00	https://drive.google.com/file/d/1SJtPtL0blWJxrRM4bG5SMtK_3zWttGyF/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	61893.00	300579.00	0.0000	40904.00	226859.00	10000.00	25000.00	70000.00	8000.00	20000.00	0.00	0.00	0.00
d633f0b7-66c4-4a25-b170-d6de164fd5e6	Safari	Diesel	Safari Accomplished X AT	Automatic	2349890.00	https://drive.google.com/file/d/1SJtPtL0blWJxrRM4bG5SMtK_3zWttGyF/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	64028.00	322935.00	0.0000	43270.00	243626.00	10000.00	25000.00	70000.00	8000.00	20000.00	0.00	0.00	0.00
85c85d05-61de-413c-8f3d-945086a3c9bb	Safari	Diesel	Safari Accomplished X DK	Manual	2236290.00	https://drive.google.com/file/d/1SJtPtL0blWJxrRM4bG5SMtK_3zWttGyF/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	62565.00	307599.00	0.0000	41647.00	232124.00	10000.00	25000.00	70000.00	8000.00	20000.00	0.00	0.00	0.00
69d7319b-7d8f-42ef-88e9-84965e19c560	Safari	Diesel	Safari Accomplished X DK AT	Automatic	2401890.00	https://drive.google.com/file/d/1SJtPtL0blWJxrRM4bG5SMtK_3zWttGyF/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	64698.00	329955.00	0.0000	44013.00	248891.00	10000.00	25000.00	70000.00	8000.00	20000.00	0.00	0.00	0.00
575b84ec-d4e4-4ebc-800a-807227729d6d	Safari	Diesel	Safari Accomplished X+	Manual	2373490.00	https://drive.google.com/file/d/1SJtPtL0blWJxrRM4bG5SMtK_3zWttGyF/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	64332.00	326121.00	0.0000	43607.00	246016.00	10000.00	25000.00	70000.00	8000.00	20000.00	0.00	0.00	0.00
03c43354-7b46-49fe-adee-a9dad06f2d3f	Safari	Diesel	Safari Accomplished X+ 6S	Manual	2382990.00	https://drive.google.com/file/d/1SJtPtL0blWJxrRM4bG5SMtK_3zWttGyF/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	64455.00	327404.00	0.0000	43743.00	246978.00	10000.00	25000.00	70000.00	8000.00	20000.00	0.00	0.00	0.00
b096ef1e-8c2b-4e2d-8a53-d0880a0081e2	Safari	Diesel	Safari Accomplished X+ AT	Automatic	2515390.00	https://drive.google.com/file/d/1SJtPtL0blWJxrRM4bG5SMtK_3zWttGyF/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	66161.00	345278.00	0.0000	45634.00	260384.00	10000.00	25000.00	70000.00	8000.00	20000.00	0.00	0.00	0.00
09cab778-aae1-4b00-8638-ff3525094c93	Safari	Diesel	Safari Accomplished X+ AT 6S	Automatic	2524890.00	https://drive.google.com/file/d/1SJtPtL0blWJxrRM4bG5SMtK_3zWttGyF/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	66284.00	346560.00	0.0000	45770.00	261345.00	10000.00	25000.00	70000.00	8000.00	20000.00	0.00	0.00	0.00
1d30b796-d09e-4121-bcaa-ebe673cd0766	Safari	Diesel	Safari Accomplished X+ DK	Manual	2406590.00	https://drive.google.com/file/d/1SJtPtL0blWJxrRM4bG5SMtK_3zWttGyF/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	64760.00	330590.00	0.0000	44080.00	249368.00	10000.00	25000.00	70000.00	8000.00	20000.00	0.00	0.00	0.00
236059e7-b000-4343-a258-9389b8fdcb00	Safari	Diesel	Safari Accomplished X+ DK 6S	Manual	2416090.00	https://drive.google.com/file/d/1SJtPtL0blWJxrRM4bG5SMtK_3zWttGyF/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	64882.00	331872.00	0.0000	44216.00	250329.00	10000.00	25000.00	70000.00	8000.00	20000.00	0.00	0.00	0.00
68237972-dcd8-4ba3-8536-842dd2beb708	Safari	Diesel	Safari Accomplished X+ DK AT	Automatic	2548490.00	https://drive.google.com/file/d/1SJtPtL0blWJxrRM4bG5SMtK_3zWttGyF/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	66587.00	349746.00	0.0000	46107.00	263735.00	10000.00	25000.00	70000.00	8000.00	20000.00	0.00	0.00	0.00
a02cec54-c33e-41ca-be6d-aef93013bb1a	Safari	Diesel	Safari Accomplished X+ STLTH	Manual	2444490.00	https://drive.google.com/file/d/1SJtPtL0blWJxrRM4bG5SMtK_3zWttGyF/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	65248.00	335706.00	0.0000	44621.00	253205.00	10000.00	25000.00	70000.00	8000.00	20000.00	0.00	0.00	0.00
ab544c59-7954-48cb-b8b9-052c5c4f5c8d	Safari	Diesel	Safari Accomplished X+AT STLTH	Manual	2586290.00	https://drive.google.com/file/d/1SJtPtL0blWJxrRM4bG5SMtK_3zWttGyF/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	67076.00	354849.00	0.0000	46647.00	267562.00	10000.00	25000.00	70000.00	8000.00	20000.00	0.00	0.00	0.00
da8d9902-8efe-40a4-ba1e-e77b1fc44706	Safari	Diesel	Safari Accomplished X+AT6S STH	Manual	2595790.00	https://drive.google.com/file/d/1SJtPtL0blWJxrRM4bG5SMtK_3zWttGyF/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	67199.00	356132.00	0.0000	46783.00	268524.00	10000.00	25000.00	70000.00	8000.00	20000.00	0.00	0.00	0.00
40bc3f54-f98c-4ce7-ace6-0f19901155b6	Safari	Diesel	Safari Accomplished X+DK AT 6S	Automatic	2557990.00	https://drive.google.com/file/d/1SJtPtL0blWJxrRM4bG5SMtK_3zWttGyF/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	66710.00	351029.00	0.0000	46243.00	264697.00	10000.00	25000.00	70000.00	8000.00	20000.00	0.00	0.00	0.00
91c41081-2242-4852-b96d-0f4ad6f6bcea	Safari	Diesel	Safari Adventure X+	Manual	1890990.00	https://drive.google.com/file/d/1SJtPtL0blWJxrRM4bG5SMtK_3zWttGyF/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	58115.00	260984.00	0.0000	36714.00	197163.00	10000.00	25000.00	70000.00	8000.00	20000.00	0.00	0.00	0.00
5f2caada-b1e2-4ab1-9819-33d096cc26fe	Safari	Diesel	Safari Adventure X+ AT	Automatic	2051890.00	https://drive.google.com/file/d/1SJtPtL0blWJxrRM4bG5SMtK_3zWttGyF/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	60187.00	282705.00	0.0000	39013.00	213454.00	10000.00	25000.00	70000.00	8000.00	20000.00	0.00	0.00	0.00
97bc94a0-6e6d-4df7-8ab8-6f13e7087400	Safari	Diesel	Safari Adventure X+ DK	Manual	1943090.00	https://drive.google.com/file/d/1SJtPtL0blWJxrRM4bG5SMtK_3zWttGyF/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	58786.00	268017.00	0.0000	37458.00	202438.00	10000.00	25000.00	70000.00	8000.00	20000.00	0.00	0.00	0.00
ad4cae6b-0372-4b34-9bba-22a827a4d9b6	Safari	Diesel	Safari Adventure X+ DK AT	Automatic	2103890.00	https://drive.google.com/file/d/1SJtPtL0blWJxrRM4bG5SMtK_3zWttGyF/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	60859.00	289725.00	0.0000	39756.00	218719.00	10000.00	25000.00	70000.00	8000.00	20000.00	0.00	0.00	0.00
f329e57d-368f-4bbc-a632-9171f7571124	Safari	Diesel	Safari Pure X	Manual	1749190.00	https://drive.google.com/file/d/1SJtPtL0blWJxrRM4bG5SMtK_3zWttGyF/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	56287.00	241841.00	0.0000	34688.00	182806.00	10000.00	25000.00	70000.00	8000.00	20000.00	0.00	0.00	0.00
0fcd96d4-5a44-403b-a8c3-8f92a2a74161	Safari	Diesel	Safari Pure X AT	Automatic	1891090.00	https://drive.google.com/file/d/1SJtPtL0blWJxrRM4bG5SMtK_3zWttGyF/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	58116.00	260997.00	0.0000	36716.00	197173.00	10000.00	25000.00	70000.00	8000.00	20000.00	0.00	0.00	0.00
43896644-781c-4d3e-bc8c-72ffce0b31eb	Safari	Diesel	Safari Pure X DK	Manual	1801190.00	https://drive.google.com/file/d/1SJtPtL0blWJxrRM4bG5SMtK_3zWttGyF/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	56957.00	248861.00	0.0000	35431.00	188071.00	10000.00	25000.00	70000.00	8000.00	20000.00	0.00	0.00	0.00
615d9521-9acc-4911-a0b1-c944740b4c3b	Safari	Diesel	Safari Pure X DK AT	Automatic	1952590.00	https://drive.google.com/file/d/1SJtPtL0blWJxrRM4bG5SMtK_3zWttGyF/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	58908.00	269300.00	0.0000	37594.00	203400.00	10000.00	25000.00	70000.00	8000.00	20000.00	0.00	0.00	0.00
6543de32-aa51-4662-9b26-0591156fde4a	Safari	Diesel	Safari Smart	Manual	1466290.00	https://drive.google.com/file/d/1SJtPtL0blWJxrRM4bG5SMtK_3zWttGyF/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	52641.00	203649.00	0.0000	30647.00	154162.00	10000.00	25000.00	70000.00	8000.00	20000.00	0.00	0.00	0.00
085d60f2-2d6d-4d2a-838c-6bd5ebdb9e70	Safari	Petrol	Safari Accomplished UL 6S P	Manual	2342990.00	https://drive.google.com/file/d/1SJtPtL0blWJxrRM4bG5SMtK_3zWttGyF/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	63939.00	268286.00	0.0000	36593.00	202390.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
c2ebf9c6-a9e0-4ab7-847b-7c7eb71a9377	Safari	Petrol	Safari Accomplished UL AT 6S P	Automatic	2484890.00	https://drive.google.com/file/d/1SJtPtL0blWJxrRM4bG5SMtK_3zWttGyF/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	65767.00	284250.00	0.0000	38282.00	214363.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
d807dabd-5f76-44ea-8d20-5f596b750c3d	Safari	Petrol	Safari Accomplished UL AT P	Automatic	2475390.00	https://drive.google.com/file/d/1SJtPtL0blWJxrRM4bG5SMtK_3zWttGyF/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	65647.00	283181.00	0.0000	38169.00	213561.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
4931ad86-b64e-4b36-954a-85d966b62c32	Safari	Petrol	Safari Accomplished UL P	Manual	2333490.00	https://drive.google.com/file/d/1SJtPtL0blWJxrRM4bG5SMtK_3zWttGyF/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	63818.00	267218.00	0.0000	36480.00	201589.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
cb00ba39-23c2-4034-9893-d0c0726ca48e	Safari	Petrol	Safari Accomplished UL RDK P	Manual	2368490.00	https://drive.google.com/file/d/1SJtPtL0blWJxrRM4bG5SMtK_3zWttGyF/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	64269.00	271155.00	0.0000	36896.00	204541.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
128c1740-030a-4642-a1f4-0ed0fece9246	Safari	Petrol	Safari Accomplished UL RDK6S P	Manual	2377990.00	https://drive.google.com/file/d/1SJtPtL0blWJxrRM4bG5SMtK_3zWttGyF/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	64391.00	272224.00	0.0000	37009.00	205343.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
760939c3-1917-439c-8584-683519b3eb09	Safari	Petrol	Safari Accomplished UL RDKAT P	Manual	2510390.00	https://drive.google.com/file/d/1SJtPtL0blWJxrRM4bG5SMtK_3zWttGyF/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	66098.00	287119.00	0.0000	38586.00	216514.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
4abf1438-811b-45d9-ac2d-6b4b5ee41818	Safari	Petrol	Safari Accomplished ULRDKAT6 P	Manual	2519890.00	https://drive.google.com/file/d/1SJtPtL0blWJxrRM4bG5SMtK_3zWttGyF/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	66220.00	288188.00	0.0000	38699.00	217316.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
44da24d9-0b1d-492a-b8ee-cdcbf657963d	Safari	Petrol	Safari Accomplished X AT P	Automatic	2249890.00	https://drive.google.com/file/d/1SJtPtL0blWJxrRM4bG5SMtK_3zWttGyF/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	62739.00	257813.00	0.0000	35484.00	194535.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
2ea9f36f-c7c4-4c04-8299-0ef96310da38	Safari	Petrol	Safari Accomplished X DK AT P	Automatic	2301890.00	https://drive.google.com/file/d/1SJtPtL0blWJxrRM4bG5SMtK_3zWttGyF/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	63410.00	263663.00	0.0000	36103.00	198922.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
fc9acb77-85b0-4dfc-9b9d-b0252f5e3f64	Safari	Petrol	Safari Accomplished X DK P	Manual	2136290.00	https://drive.google.com/file/d/1SJtPtL0blWJxrRM4bG5SMtK_3zWttGyF/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	61276.00	245033.00	0.0000	34132.00	184950.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
a609b1bf-829c-4d08-b93a-ad158e23602e	Safari	Petrol	Safari Accomplished X P	Manual	2084290.00	https://drive.google.com/file/d/1SJtPtL0blWJxrRM4bG5SMtK_3zWttGyF/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	60605.00	239183.00	0.0000	33513.00	180562.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
af8a715f-64d0-4ef4-a292-f54b00757352	Safari	Petrol	Safari Accomplished X+ 6S P	Manual	2282990.00	https://drive.google.com/file/d/1SJtPtL0blWJxrRM4bG5SMtK_3zWttGyF/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	63167.00	261536.00	0.0000	35878.00	197327.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
a3a243d4-f58f-48af-ab89-8f2ec0ef02e8	Safari	Petrol	Safari Accomplished X+ AT 6S P	Automatic	2424890.00	https://drive.google.com/file/d/1SJtPtL0blWJxrRM4bG5SMtK_3zWttGyF/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	64996.00	277500.00	0.0000	37568.00	209300.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
ebf9c07f-f685-46a4-8707-bd043adc3922	Safari	Petrol	Safari Accomplished X+ AT P	Automatic	2415390.00	https://drive.google.com/file/d/1SJtPtL0blWJxrRM4bG5SMtK_3zWttGyF/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	64873.00	276431.00	0.0000	37455.00	208498.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
94a9a538-6b1e-4ce4-abd7-ce87d6db5dcb	Safari	Petrol	Safari Accomplished X+ DK 6S P	Manual	2316090.00	https://drive.google.com/file/d/1SJtPtL0blWJxrRM4bG5SMtK_3zWttGyF/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	63593.00	265260.00	0.0000	36273.00	200120.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
41acaf68-fa19-4a83-9849-bfb55a3aac6a	Safari	Petrol	Safari Accomplished X+ DK AT P	Automatic	2448490.00	https://drive.google.com/file/d/1SJtPtL0blWJxrRM4bG5SMtK_3zWttGyF/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	65299.00	280155.00	0.0000	37849.00	211291.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
27600eb4-a32b-45fc-91d6-ec23018ac8bd	Safari	Petrol	Safari Accomplished X+ DK P	Manual	2306590.00	https://drive.google.com/file/d/1SJtPtL0blWJxrRM4bG5SMtK_3zWttGyF/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	63470.00	264191.00	0.0000	36159.00	199318.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
316322c7-610c-4add-b2ca-309aab40a963	Safari	Petrol	Safari Accomplished X+ P	Manual	2273490.00	https://drive.google.com/file/d/1SJtPtL0blWJxrRM4bG5SMtK_3zWttGyF/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	63044.00	260468.00	0.0000	35765.00	196526.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
2cd03f27-39ca-4acb-b1e8-c3b59f00f8c3	Safari	Petrol	Safari Accomplished X+DK AT 6S P	Automatic	2457990.00	https://drive.google.com/file/d/1SJtPtL0blWJxrRM4bG5SMtK_3zWttGyF/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	65422.00	281224.00	0.0000	37962.00	212093.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
d1683931-975c-4948-a7de-59357b6f6386	Safari	Petrol	Safari Adventure X+ AT P	Automatic	1935990.00	https://drive.google.com/file/d/1SJtPtL0blWJxrRM4bG5SMtK_3zWttGyF/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	58694.00	222499.00	0.0000	31748.00	168049.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
3a40e691-6618-4334-9fa1-876a13b0ea90	Safari	Petrol	Safari Adventure X+ DK AT P	Automatic	1988090.00	https://drive.google.com/file/d/1SJtPtL0blWJxrRM4bG5SMtK_3zWttGyF/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	59366.00	228360.00	0.0000	32368.00	172445.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
2c37de46-fa44-4a2e-816d-cef83c5ecb30	Safari	Petrol	Safari Adventure X+ DK P	Manual	1827190.00	https://drive.google.com/file/d/1SJtPtL0blWJxrRM4bG5SMtK_3zWttGyF/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	57291.00	210259.00	0.0000	30452.00	158869.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
68a0263c-fa2a-4970-8f99-c2feab9bbcf2	Safari	Petrol	Safari Adventure X+ P	Manual	1775090.00	https://drive.google.com/file/d/1SJtPtL0blWJxrRM4bG5SMtK_3zWttGyF/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	56620.00	204398.00	0.0000	29832.00	154474.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
b273842e-35e7-4912-8fab-41004dd67b16	Safari	Petrol	Safari Pure X AT P	Automatic	1791090.00	https://drive.google.com/file/d/1SJtPtL0blWJxrRM4bG5SMtK_3zWttGyF/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	56826.00	206198.00	0.0000	30023.00	155824.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
433b4e6a-dfd0-470f-afee-9ccadcd51b6b	Safari	Petrol	Safari Pure X DK AT P	Automatic	1852590.00	https://drive.google.com/file/d/1SJtPtL0blWJxrRM4bG5SMtK_3zWttGyF/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	57619.00	213116.00	0.0000	30755.00	161012.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
a02b5a84-8ac5-41c3-a188-78c02ebee81b	Safari	Petrol	Safari Pure X DK P	Manual	1701190.00	https://drive.google.com/file/d/1SJtPtL0blWJxrRM4bG5SMtK_3zWttGyF/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	55668.00	196084.00	0.0000	28952.00	148238.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
98135f8b-b414-4b63-be8a-7de5f1c2412e	Safari	Petrol	Safari Pure X P	Manual	1649190.00	https://drive.google.com/file/d/1SJtPtL0blWJxrRM4bG5SMtK_3zWttGyF/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	54999.00	190234.00	0.0000	28333.00	143851.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
c975710d-9f18-47d3-9383-8ee91f146c8d	Safari	Petrol	Safari Smart P	Manual	1329000.00	https://drive.google.com/file/d/1SJtPtL0blWJxrRM4bG5SMtK_3zWttGyF/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	50872.00	154213.00	0.0000	24521.00	116835.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
7d48fdbd-bf77-433a-ac3f-008d913f0b80	Sierra	Diesel	Sierra Accomplished + 1.5 D	Manual	2029000.00	https://drive.google.com/file/d/1IFWgg2ustHpSB7Q37tiCeNjn_capaUtK/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	55556.00	278615.00	0.0000	37686.00	210136.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
5b5685d0-c3b4-45c6-922b-1ec5da21bdb5	Sierra	Diesel	Sierra Accomplished + AT 1.5 D	Automatic	2129000.00	https://drive.google.com/file/d/1IFWgg2ustHpSB7Q37tiCeNjn_capaUtK/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	57546.00	292115.00	0.0000	39114.00	220261.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
de71817c-ae54-4cf5-ac9f-d2dd22e27a16	Sierra	Diesel	Sierra Accomplished 1.5 D	Manual	1899000.00	https://drive.google.com/file/d/1IFWgg2ustHpSB7Q37tiCeNjn_capaUtK/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	52967.00	261065.00	0.0000	35829.00	196974.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
626b1eec-f5d3-4469-ba6a-4431ef947c13	Sierra	Diesel	Sierra Accomplished AT 1.5 D	Automatic	1999000.00	https://drive.google.com/file/d/1IFWgg2ustHpSB7Q37tiCeNjn_capaUtK/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	54959.00	274565.00	0.0000	37257.00	207099.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
79859f98-a6b9-4414-b52c-ca32cfd78deb	Sierra	Diesel	Sierra Adventure + 1.5 D	Manual	1719000.00	https://drive.google.com/file/d/1IFWgg2ustHpSB7Q37tiCeNjn_capaUtK/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	49382.00	236765.00	0.0000	33257.00	178749.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
04164f51-b85b-491b-8a5e-5c0e54f60f7a	Sierra	Diesel	Sierra Adventure + AT 1.5 D	Automatic	1849000.00	https://drive.google.com/file/d/1IFWgg2ustHpSB7Q37tiCeNjn_capaUtK/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	51971.00	254315.00	0.0000	35114.00	191911.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
668ed7dc-624f-4552-91fb-606273b57bda	Sierra	Diesel	Sierra Adventure 1.5 D	Manual	1649000.00	https://drive.google.com/file/d/1IFWgg2ustHpSB7Q37tiCeNjn_capaUtK/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	47988.00	227315.00	0.0000	32257.00	171661.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
88e36457-cacd-48b7-b7a0-c499cfc4d79b	Sierra	Diesel	Sierra Pure + 1.5 AT D	Automatic	1749000.00	https://drive.google.com/file/d/1IFWgg2ustHpSB7Q37tiCeNjn_capaUtK/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	49980.00	240815.00	0.0000	33686.00	181786.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
5a58d9f8-4172-4bf2-9b76-579afeaa3e5a	Sierra	Diesel	Sierra Pure + 1.5 D	Manual	1599000.00	https://drive.google.com/file/d/1IFWgg2ustHpSB7Q37tiCeNjn_capaUtK/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	46992.00	220565.00	0.0000	31543.00	166599.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
922de244-bcfc-4116-ac4d-69842bde252d	Sierra	Diesel	Sierra Pure 1.5 AT D	Automatic	1599000.00	https://drive.google.com/file/d/1IFWgg2ustHpSB7Q37tiCeNjn_capaUtK/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	46992.00	220565.00	0.0000	31543.00	166599.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
02e6d081-9a6d-4894-b23a-4c914073453c	Sierra	Diesel	Sierra Pure 1.5 D	Manual	1449000.00	https://drive.google.com/file/d/1IFWgg2ustHpSB7Q37tiCeNjn_capaUtK/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	44006.00	200315.00	0.0000	29400.00	151411.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
5ab5e271-a113-4e33-8a0f-aaf7dc843a0f	Sierra	Diesel	Sierra Smart + 1.5 D	Manual	1299000.00	https://drive.google.com/file/d/1IFWgg2ustHpSB7Q37tiCeNjn_capaUtK/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	41018.00	180065.00	0.0000	27257.00	136224.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
c239d6ab-4285-41d5-921f-851428e68677	Sierra	Petrol	Sierra Accomplished + AT TGDi Hyperion 1.5 P	Automatic	2099000.00	https://drive.google.com/file/d/1IFWgg2ustHpSB7Q37tiCeNjn_capaUtK/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	56949.00	240838.00	0.0000	33688.00	181804.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
aa527dae-48bb-44b8-85ad-4d9b8cb6fc51	Sierra	Petrol	Sierra Accomplished 1.5 P	Manual	1799000.00	https://drive.google.com/file/d/1IFWgg2ustHpSB7Q37tiCeNjn_capaUtK/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	50975.00	207088.00	0.0000	30117.00	156491.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
d963bf50-1545-4413-bdf0-47fd542b27c5	Sierra	Petrol	Sierra Accomplished AT TGDi Hyperion 1.5 P	Automatic	1999000.00	https://drive.google.com/file/d/1IFWgg2ustHpSB7Q37tiCeNjn_capaUtK/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	54959.00	229588.00	0.0000	32498.00	173366.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
95b1985d-0535-4112-9ddf-2322e99958ea	Sierra	Petrol	Sierra Adventure + 1.5 P	Manual	1599000.00	https://drive.google.com/file/d/1IFWgg2ustHpSB7Q37tiCeNjn_capaUtK/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	46992.00	184588.00	0.0000	27736.00	139616.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
dae9d003-6b12-4aa6-8f59-34f63c264e5d	Sierra	Petrol	Sierra Adventure + AT TGDi Hyperion 1.5 P	Automatic	1799000.00	https://drive.google.com/file/d/1IFWgg2ustHpSB7Q37tiCeNjn_capaUtK/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	50975.00	207088.00	0.0000	30117.00	156491.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
4bde6f63-6303-4f44-8c8c-5a43bdd8f686	Sierra	Petrol	Sierra Adventure 1.5 P	Manual	1529000.00	https://drive.google.com/file/d/1IFWgg2ustHpSB7Q37tiCeNjn_capaUtK/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	45599.00	176713.00	0.0000	26902.00	133710.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
f05fee05-91a9-4f8c-9e1c-690a7d21e21d	Sierra	Petrol	Sierra Adventure DCA 1.5 P	DCA	1679000.00	https://drive.google.com/file/d/1IFWgg2ustHpSB7Q37tiCeNjn_capaUtK/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	48585.00	193588.00	0.0000	28688.00	146366.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
6dd2cf94-40b7-42c4-9a4d-8b9380fb66cb	Sierra	Petrol	Sierra Pure + 1.5 DCA P	DCA	1599000.00	https://drive.google.com/file/d/1IFWgg2ustHpSB7Q37tiCeNjn_capaUtK/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	46992.00	184588.00	0.0000	27736.00	139616.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
7271cd85-6c94-4e32-9849-3bd41d1ee498	Sierra	Petrol	Sierra Pure + 1.5 P	Manual	1449000.00	https://drive.google.com/file/d/1IFWgg2ustHpSB7Q37tiCeNjn_capaUtK/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	44006.00	167713.00	0.0000	25950.00	126960.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
7f70452d-3d77-4598-8755-01fc42030eef	Sierra	Petrol	Sierra Pure 1.5 DCA P	DCA	1449000.00	https://drive.google.com/file/d/1IFWgg2ustHpSB7Q37tiCeNjn_capaUtK/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	44006.00	167713.00	0.0000	25950.00	126960.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
cef2dfe0-42d0-4b32-a37e-919a11135646	Sierra	Petrol	Sierra Pure 1.5 P	Manual	1299000.00	https://drive.google.com/file/d/1IFWgg2ustHpSB7Q37tiCeNjn_capaUtK/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	41018.00	150838.00	0.0000	24164.00	114304.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
10c7f8a4-0f2f-4fd5-a826-24dc1789e3a4	Sierra	Petrol	Sierra Smart + 1.5 P	Manual	1149000.00	https://drive.google.com/file/d/1IFWgg2ustHpSB7Q37tiCeNjn_capaUtK/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	38031.00	133963.00	0.0000	22379.00	101647.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
c2340f13-3a1e-420d-8c31-8a3f49936b0f	Tiago	CNG	Tiago XE CNG MYC	Manual	548990.00	https://drive.google.com/file/d/1ZA_jUREOOKQqy471bgFZCBYajPz3zlLD/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	21356.00	60285.00	0.0000	15679.00	46389.00	0.00	0.00	25000.00	3000.00	0.00	0.00	0.00	0.00
b921b47d-2de6-4a68-a1f3-bae413b089e2	Tiago	CNG	Tiago XM CNG MYC	Manual	622090.00	https://drive.google.com/file/d/1ZA_jUREOOKQqy471bgFZCBYajPz3zlLD/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	22260.00	67687.00	0.0000	16608.00	51940.00	10000.00	10000.00	25000.00	3000.00	0.00	0.00	0.00	0.00
f890475d-03dc-426f-b6c7-e38d6ba972ef	Tiago	CNG	Tiago XT CNG MYC	Manual	672490.00	https://drive.google.com/file/d/1ZA_jUREOOKQqy471bgFZCBYajPz3zlLD/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	22884.00	72790.00	0.0000	17249.00	55768.00	10000.00	10000.00	25000.00	3000.00	0.00	0.00	0.00	0.00
f80d580e-1597-45a2-94b3-1d6e910da695	Tiago	CNG	Tiago XTA CNG MYC	Manual	722790.00	https://drive.google.com/file/d/1ZA_jUREOOKQqy471bgFZCBYajPz3zlLD/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	23506.00	77882.00	0.0000	17888.00	59587.00	10000.00	10000.00	25000.00	3000.00	0.00	0.00	0.00	0.00
ea861568-f02a-4464-a0cf-1f6d2cfeaa1c	Tiago	CNG	Tiago XZ CNG MYC	Manual	731890.00	https://drive.google.com/file/d/1ZA_jUREOOKQqy471bgFZCBYajPz3zlLD/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	23618.00	78804.00	0.0000	18004.00	60278.00	10000.00	10000.00	25000.00	3000.00	0.00	0.00	0.00	0.00
9982fd7e-ce3d-4ce3-8b35-4cf31a7d11a8	Tiago	CNG	Tiago XZ NRG CNG MYC	Manual	759390.00	https://drive.google.com/file/d/1ZA_jUREOOKQqy471bgFZCBYajPz3zlLD/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	23958.00	81588.00	0.0000	18353.00	62366.00	10000.00	10000.00	25000.00	3000.00	0.00	0.00	0.00	0.00
a5d0e671-e040-434d-afa8-ca58b3038467	Tiago	CNG	Tiago XZA CNG MYC	Manual	782190.00	https://drive.google.com/file/d/1ZA_jUREOOKQqy471bgFZCBYajPz3zlLD/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	24240.00	83897.00	0.0000	18643.00	64098.00	10000.00	10000.00	25000.00	3000.00	0.00	0.00	0.00	0.00
2cae7942-fd3c-4c2e-b064-28acf1df2d36	Tiago	CNG	Tiago XZA NRG CNG MYC	Manual	809690.00	https://drive.google.com/file/d/1ZA_jUREOOKQqy471bgFZCBYajPz3zlLD/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	24581.00	86681.00	0.0000	18993.00	66186.00	10000.00	10000.00	25000.00	3000.00	0.00	0.00	0.00	0.00
7e9d8ab2-537c-4695-be91-d7b2c9ca323a	Tiago	EV	Tiago EV LR XT	Automatic	1014000.00	https://drive.google.com/file/d/1_qF1d6JDnhuRq8Mj4AS0Abqs9IkPx25S/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	28154.00	2200.00	0.0000	2200.00	1600.00	0.00	20000.00	25000.00	0.00	0.00	8000.00	5000.00	70000.00
cbb15124-7577-4e7d-bd4c-26bf9b901619	Tiago	EV	Tiago EV LR XZ+ Tech Lux	Automatic	1114000.00	https://drive.google.com/file/d/1_qF1d6JDnhuRq8Mj4AS0Abqs9IkPx25S/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	29395.00	2200.00	0.0000	2200.00	1600.00	0.00	20000.00	25000.00	0.00	0.00	8000.00	5000.00	100000.00
704d7c3b-c6ee-4573-b3c3-6b13563e4acc	Tiago	EV	Tiago EV MR XE	Automatic	799000.00	https://drive.google.com/file/d/1_qF1d6JDnhuRq8Mj4AS0Abqs9IkPx25S/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	25484.00	2200.00	0.0000	2200.00	1600.00	0.00	20000.00	25000.00	0.00	0.00	8000.00	5000.00	40000.00
31596498-0461-450a-9f86-383371d6b00a	Tiago	Petrol	Tiago (P) XE MYC	Manual	457490.00	https://drive.google.com/file/d/1ZA_jUREOOKQqy471bgFZCBYajPz3zlLD/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	20223.00	51021.00	0.0000	14516.00	39441.00	0.00	0.00	25000.00	3000.00	0.00	0.00	0.00	0.00
1d6b7593-51bb-4f4c-98a8-4fc995afe6a1	Tiago	Petrol	Tiago (P) XM MYC	Manual	530690.00	https://drive.google.com/file/d/1ZA_jUREOOKQqy471bgFZCBYajPz3zlLD/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	21128.00	58432.00	0.0000	15446.00	44999.00	10000.00	10000.00	25000.00	3000.00	0.00	0.00	0.00	0.00
efa9bff1-1c37-49da-a18c-b57da361a225	Tiago	Petrol	Tiago (P) XT MYC	Manual	580990.00	https://drive.google.com/file/d/1ZA_jUREOOKQqy471bgFZCBYajPz3zlLD/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	21751.00	63525.00	0.0000	16085.00	48819.00	10000.00	10000.00	25000.00	3000.00	0.00	0.00	0.00	0.00
a3a76340-6050-4c7b-814e-9678c6809b0e	Tiago	Petrol	Tiago (P) XTA MYC	Automatic	631290.00	https://drive.google.com/file/d/1ZA_jUREOOKQqy471bgFZCBYajPz3zlLD/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	22373.00	68618.00	0.0000	16725.00	52639.00	10000.00	10000.00	25000.00	3000.00	0.00	0.00	0.00	0.00
1c6b6db5-2fd6-4b79-a038-ec1e1ff57f9b	Tiago	Petrol	Tiago (P) XZ MYC	Manual	640390.00	https://drive.google.com/file/d/1ZA_jUREOOKQqy471bgFZCBYajPz3zlLD/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	22486.00	69539.00	0.0000	16841.00	53329.00	10000.00	10000.00	25000.00	3000.00	0.00	0.00	0.00	0.00
47bc3d78-3520-4ff8-9659-a4196b30f105	Tiago	Petrol	Tiago (P) XZ NRG MYC	Manual	667890.00	https://drive.google.com/file/d/1ZA_jUREOOKQqy471bgFZCBYajPz3zlLD/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	22826.00	72324.00	0.0000	17190.00	55418.00	10000.00	10000.00	25000.00	3000.00	0.00	0.00	0.00	0.00
cc339866-e62b-4734-8f7b-dbf6e15e058d	Tiago	Petrol	Tiago (P) XZ+ MYC	Manual	676990.00	https://drive.google.com/file/d/1ZA_jUREOOKQqy471bgFZCBYajPz3zlLD/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	22938.00	73245.00	0.0000	17306.00	56109.00	10000.00	10000.00	25000.00	3000.00	0.00	0.00	0.00	0.00
0fe1db9c-5fe9-4558-ba76-956759f1f0a3	Tiago	Petrol	Tiago (P) XZA MYC	Automatic	690790.00	https://drive.google.com/file/d/1ZA_jUREOOKQqy471bgFZCBYajPz3zlLD/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	23109.00	74642.00	0.0000	17481.00	57157.00	10000.00	10000.00	25000.00	3000.00	0.00	0.00	0.00	0.00
13807622-7587-455b-8002-b6fa1a90c1a9	Tiago	Petrol	Tiago (P) XZA NRG MYC	Automatic	718190.00	https://drive.google.com/file/d/1ZA_jUREOOKQqy471bgFZCBYajPz3zlLD/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	23449.00	77417.00	0.0000	17830.00	59238.00	10000.00	10000.00	25000.00	3000.00	0.00	0.00	0.00	0.00
6f5f9441-1100-4e75-95cf-a50c93f6729e	Tigor	CNG	Tigor XT CNG MYC	Manual	713590.00	https://drive.google.com/file/d/1gwzj2Jt1sLMvx9PaChNqRTjMwQwstZKD/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	23392.00	76951.00	0.0000	17771.00	58888.00	15000.00	10000.00	15000.00	3000.00	0.00	0.00	0.00	0.00
743cf735-4b5e-48c3-936e-00b969bad69d	Tigor	CNG	Tigor XZ CNG MYC	Manual	768490.00	https://drive.google.com/file/d/1gwzj2Jt1sLMvx9PaChNqRTjMwQwstZKD/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	24071.00	82510.00	0.0000	18469.00	63058.00	15000.00	10000.00	15000.00	3000.00	0.00	0.00	0.00	0.00
94e80f89-3d11-41f2-8591-17f359bcc405	Tigor	CNG	Tigor XZ+ CNG MYC	Manual	823390.00	https://drive.google.com/file/d/1gwzj2Jt1sLMvx9PaChNqRTjMwQwstZKD/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	24751.00	88068.00	0.0000	19167.00	67226.00	15000.00	10000.00	15000.00	3000.00	0.00	0.00	0.00	0.00
61def68d-9e60-4bb2-a1b8-f50e2357dac2	Tigor	CNG	Tigor XZ+ Lux CNG MYC	Manual	869090.00	https://drive.google.com/file/d/1gwzj2Jt1sLMvx9PaChNqRTjMwQwstZKD/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	25316.00	92695.00	0.0000	19748.00	70696.00	15000.00	10000.00	15000.00	3000.00	0.00	0.00	0.00	0.00
d310d773-2e1d-44a5-97ec-f193850058df	Tigor	CNG	Tigor XZA CNG MYC	Automatic	818790.00	https://drive.google.com/file/d/1gwzj2Jt1sLMvx9PaChNqRTjMwQwstZKD/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	24694.00	87602.00	0.0000	19108.00	66877.00	15000.00	10000.00	15000.00	3000.00	0.00	0.00	0.00	0.00
1167412d-7423-4ea2-9dac-2e0ac9b59433	Tigor	CNG	Tigor XZA+ CNG MYC	Automatic	873690.00	https://drive.google.com/file/d/1gwzj2Jt1sLMvx9PaChNqRTjMwQwstZKD/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	25372.00	93161.00	0.0000	19806.00	71046.00	15000.00	10000.00	15000.00	3000.00	0.00	0.00	0.00	0.00
85bbd9b0-cf28-4ee6-bd75-27793467de48	Tigor	Petrol	Tigor (P) XM MYC	Manual	548990.00	https://drive.google.com/file/d/1gwzj2Jt1sLMvx9PaChNqRTjMwQwstZKD/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	21356.00	60285.00	0.0000	15679.00	46389.00	15000.00	10000.00	15000.00	3000.00	0.00	0.00	0.00	0.00
0706de1d-bb76-448f-9a9b-b272cc11238d	Tigor	Petrol	Tigor (P) XT MYC	Manual	621990.00	https://drive.google.com/file/d/1gwzj2Jt1sLMvx9PaChNqRTjMwQwstZKD/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	22258.00	67676.00	0.0000	16607.00	51932.00	15000.00	10000.00	15000.00	3000.00	0.00	0.00	0.00	0.00
4a9fa292-ae4f-4cac-84f6-7ebeff8864f5	Tigor	Petrol	Tigor (P) XTA MYC	Automatic	672490.00	https://drive.google.com/file/d/1gwzj2Jt1sLMvx9PaChNqRTjMwQwstZKD/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	22884.00	72790.00	0.0000	17249.00	55768.00	15000.00	10000.00	15000.00	3000.00	0.00	0.00	0.00	0.00
24cffb64-0dfe-4858-95ff-4f48a60cdefc	Tigor	Petrol	Tigor (P) XZ MYC	Manual	676990.00	https://drive.google.com/file/d/1gwzj2Jt1sLMvx9PaChNqRTjMwQwstZKD/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	22938.00	73245.00	0.0000	17306.00	56109.00	15000.00	10000.00	15000.00	3000.00	0.00	0.00	0.00	0.00
655b5c85-0a86-4cdb-b5c1-31da8aef01d5	Tigor	Petrol	Tigor (P) XZ+ Lux MYC	Manual	777690.00	https://drive.google.com/file/d/1gwzj2Jt1sLMvx9PaChNqRTjMwQwstZKD/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	24184.00	83441.00	0.0000	18586.00	63756.00	15000.00	10000.00	15000.00	3000.00	0.00	0.00	0.00	0.00
050a46d9-a617-4103-ad20-e0ee2b6ed32f	Tigor	Petrol	Tigor (P) XZ+ MYC	Manual	731890.00	https://drive.google.com/file/d/1gwzj2Jt1sLMvx9PaChNqRTjMwQwstZKD/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	23618.00	78804.00	0.0000	18004.00	60278.00	15000.00	10000.00	15000.00	3000.00	0.00	0.00	0.00	0.00
4bcb24aa-e15b-428e-8598-eeb8542ba032	Tigor	Petrol	Tigor (P) XZA MYC	Automatic	727290.00	https://drive.google.com/file/d/1gwzj2Jt1sLMvx9PaChNqRTjMwQwstZKD/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	23561.00	78338.00	0.0000	17945.00	59929.00	15000.00	10000.00	15000.00	3000.00	0.00	0.00	0.00	0.00
cda5283a-88a6-42f0-ad0c-4cd0110ed955	Tigor	Petrol	Tigor (P) XZA+ MYC	Automatic	782190.00	https://drive.google.com/file/d/1gwzj2Jt1sLMvx9PaChNqRTjMwQwstZKD/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	24240.00	83897.00	0.0000	18643.00	64098.00	15000.00	10000.00	15000.00	3000.00	0.00	0.00	0.00	0.00
8ade465f-97ff-4052-a954-c48b7884bb2f	Xpres T	CNG	Xpres T XM CNG	Manual	659990.00	https://drive.google.com/file/d/1pvYp9-aFrzOtFjPr3QqT2bkwKWkw-tkG/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	21715.00	78949.00	0.0000	0.00	60387.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
71ba7eed-6078-4cd1-bf93-c50ac3e801b4	Xpres T	EV	Xpres T EV 2.0 XM 24	Automatic	1070000.00	https://drive.google.com/file/d/1pvYp9-aFrzOtFjPr3QqT2bkwKWkw-tkG/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	28849.00	5500.00	0.0000	5500.00	5500.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
0918f797-6109-4a5d-adbc-d9f888b6d7c9	Xpres T	EV	Xpres T EV 2.0 XM 32	Automatic	1199000.00	https://drive.google.com/file/d/1pvYp9-aFrzOtFjPr3QqT2bkwKWkw-tkG/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	30090.00	5500.00	0.0000	5500.00	5500.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
f94666ab-d9d3-4b3f-b689-25912a07f8f1	Xpres T	Petrol	Xpres T (P) XM	Manual	559990.00	https://drive.google.com/file/d/1pvYp9-aFrzOtFjPr3QqT2bkwKWkw-tkG/view?usp=drive_link	t	2026-03-23 06:34:08.632235+00	2026-03-23 06:34:08.632235+00	23772.00	67699.00	0.0000	0.00	51949.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00	0.00
\.


--
-- Data for Name: schema_migrations; Type: TABLE DATA; Schema: realtime; Owner: -
--

COPY realtime.schema_migrations (version, inserted_at) FROM stdin;
20211116024918	2026-03-20 15:04:42
20211116045059	2026-03-20 15:04:42
20211116050929	2026-03-20 15:04:43
20211116051442	2026-03-20 15:04:43
20211116212300	2026-03-20 19:12:58
20211116213355	2026-03-20 19:12:58
20211116213934	2026-03-20 19:12:58
20211116214523	2026-03-20 19:12:58
20211122062447	2026-03-20 19:12:58
20211124070109	2026-03-20 19:12:58
20211202204204	2026-03-20 19:12:58
20211202204605	2026-03-20 19:12:58
20211210212804	2026-03-20 19:13:00
20211228014915	2026-03-20 19:13:06
20220107221237	2026-03-20 19:13:07
20220228202821	2026-03-20 19:13:07
20220312004840	2026-03-20 19:13:07
20220603231003	2026-03-20 19:13:07
20220603232444	2026-03-20 19:13:07
20220615214548	2026-03-20 19:13:07
20220712093339	2026-03-20 19:13:07
20220908172859	2026-03-20 19:13:07
20220916233421	2026-03-20 19:13:07
20230119133233	2026-03-20 19:13:07
20230128025114	2026-03-20 19:13:07
20230128025212	2026-03-20 19:13:07
20230227211149	2026-03-20 19:13:07
20230228184745	2026-03-20 19:13:07
20230308225145	2026-03-20 19:13:07
20230328144023	2026-03-20 19:13:07
20231018144023	2026-03-20 19:13:07
20231204144023	2026-03-20 19:13:08
20231204144024	2026-03-20 19:13:08
20231204144025	2026-03-20 19:13:08
20240108234812	2026-03-20 19:13:08
20240109165339	2026-03-20 19:13:08
20240227174441	2026-03-20 19:13:08
20240311171622	2026-03-20 19:13:08
20240321100241	2026-03-20 19:13:08
20240401105812	2026-03-20 19:13:08
20240418121054	2026-03-20 19:13:08
20240523004032	2026-03-20 19:13:08
20240618124746	2026-03-20 19:13:08
20240801235015	2026-03-20 19:13:08
20240805133720	2026-03-20 19:13:08
20240827160934	2026-03-20 19:13:08
20240919163303	2026-03-20 19:13:08
20240919163305	2026-03-20 19:13:08
20241019105805	2026-03-20 19:13:08
20241030150047	2026-03-20 19:13:09
20241108114728	2026-03-20 19:13:09
20241121104152	2026-03-20 19:13:09
20241130184212	2026-03-20 19:13:09
20241220035512	2026-03-20 19:13:09
20241220123912	2026-03-20 19:13:09
20241224161212	2026-03-20 19:13:09
20250107150512	2026-03-20 19:13:09
20250110162412	2026-03-20 19:13:09
20250123174212	2026-03-20 19:13:09
20250128220012	2026-03-20 19:13:09
20250506224012	2026-03-20 19:13:09
20250523164012	2026-03-20 19:13:09
20250714121412	2026-03-20 19:13:09
20250905041441	2026-03-20 19:13:09
20251103001201	2026-03-20 19:13:09
20251120212548	2026-03-20 19:13:09
20251120215549	2026-03-20 19:13:09
20260218120000	2026-03-20 19:13:09
\.


--
-- Data for Name: subscription; Type: TABLE DATA; Schema: realtime; Owner: -
--

COPY realtime.subscription (id, subscription_id, entity, filters, claims, created_at, action_filter) FROM stdin;
\.


--
-- Data for Name: buckets; Type: TABLE DATA; Schema: storage; Owner: -
--

COPY storage.buckets (id, name, owner, created_at, updated_at, public, avif_autodetection, file_size_limit, allowed_mime_types, owner_id, type) FROM stdin;
Brochures	Brochures	\N	2026-03-21 10:11:04.259745+00	2026-03-21 10:11:04.259745+00	t	f	\N	\N	\N	STANDARD
\.


--
-- Data for Name: buckets_analytics; Type: TABLE DATA; Schema: storage; Owner: -
--

COPY storage.buckets_analytics (name, type, format, created_at, updated_at, id, deleted_at) FROM stdin;
\.


--
-- Data for Name: buckets_vectors; Type: TABLE DATA; Schema: storage; Owner: -
--

COPY storage.buckets_vectors (id, type, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: migrations; Type: TABLE DATA; Schema: storage; Owner: -
--

COPY storage.migrations (id, name, hash, executed_at) FROM stdin;
0	create-migrations-table	e18db593bcde2aca2a408c4d1100f6abba2195df	2026-03-20 15:05:12.473297
1	initialmigration	6ab16121fbaa08bbd11b712d05f358f9b555d777	2026-03-20 15:05:12.518244
2	storage-schema	f6a1fa2c93cbcd16d4e487b362e45fca157a8dbd	2026-03-20 15:05:12.534895
3	pathtoken-column	2cb1b0004b817b29d5b0a971af16bafeede4b70d	2026-03-20 15:05:12.591523
4	add-migrations-rls	427c5b63fe1c5937495d9c635c263ee7a5905058	2026-03-20 15:05:12.837423
5	add-size-functions	79e081a1455b63666c1294a440f8ad4b1e6a7f84	2026-03-20 15:05:12.844356
6	change-column-name-in-get-size	ded78e2f1b5d7e616117897e6443a925965b30d2	2026-03-20 15:05:12.850469
7	add-rls-to-buckets	e7e7f86adbc51049f341dfe8d30256c1abca17aa	2026-03-20 15:05:12.857632
8	add-public-to-buckets	fd670db39ed65f9d08b01db09d6202503ca2bab3	2026-03-20 15:05:12.862923
9	fix-search-function	af597a1b590c70519b464a4ab3be54490712796b	2026-03-20 15:05:12.869927
10	search-files-search-function	b595f05e92f7e91211af1bbfe9c6a13bb3391e16	2026-03-20 15:05:12.876387
11	add-trigger-to-auto-update-updated_at-column	7425bdb14366d1739fa8a18c83100636d74dcaa2	2026-03-20 15:05:12.8821
12	add-automatic-avif-detection-flag	8e92e1266eb29518b6a4c5313ab8f29dd0d08df9	2026-03-20 15:05:12.889229
13	add-bucket-custom-limits	cce962054138135cd9a8c4bcd531598684b25e7d	2026-03-20 15:05:12.894862
14	use-bytes-for-max-size	941c41b346f9802b411f06f30e972ad4744dad27	2026-03-20 15:05:12.900658
15	add-can-insert-object-function	934146bc38ead475f4ef4b555c524ee5d66799e5	2026-03-20 15:05:12.986532
16	add-version	76debf38d3fd07dcfc747ca49096457d95b1221b	2026-03-20 15:05:13.008363
17	drop-owner-foreign-key	f1cbb288f1b7a4c1eb8c38504b80ae2a0153d101	2026-03-20 15:05:13.014028
18	add_owner_id_column_deprecate_owner	e7a511b379110b08e2f214be852c35414749fe66	2026-03-20 15:05:13.019476
19	alter-default-value-objects-id	02e5e22a78626187e00d173dc45f58fa66a4f043	2026-03-20 15:05:13.026515
20	list-objects-with-delimiter	cd694ae708e51ba82bf012bba00caf4f3b6393b7	2026-03-20 15:05:13.032197
21	s3-multipart-uploads	8c804d4a566c40cd1e4cc5b3725a664a9303657f	2026-03-20 15:05:13.038981
22	s3-multipart-uploads-big-ints	9737dc258d2397953c9953d9b86920b8be0cdb73	2026-03-20 15:05:13.092426
23	optimize-search-function	9d7e604cddc4b56a5422dc68c9313f4a1b6f132c	2026-03-20 15:05:13.14129
24	operation-function	8312e37c2bf9e76bbe841aa5fda889206d2bf8aa	2026-03-20 15:05:13.147713
25	custom-metadata	d974c6057c3db1c1f847afa0e291e6165693b990	2026-03-20 15:05:13.16001
26	objects-prefixes	215cabcb7f78121892a5a2037a09fedf9a1ae322	2026-03-20 15:05:13.166054
27	search-v2	859ba38092ac96eb3964d83bf53ccc0b141663a6	2026-03-20 15:05:13.171565
28	object-bucket-name-sorting	c73a2b5b5d4041e39705814fd3a1b95502d38ce4	2026-03-20 15:05:13.177186
29	create-prefixes	ad2c1207f76703d11a9f9007f821620017a66c21	2026-03-20 15:05:13.183395
30	update-object-levels	2be814ff05c8252fdfdc7cfb4b7f5c7e17f0bed6	2026-03-20 15:05:13.189192
31	objects-level-index	b40367c14c3440ec75f19bbce2d71e914ddd3da0	2026-03-20 15:05:13.19469
32	backward-compatible-index-on-objects	e0c37182b0f7aee3efd823298fb3c76f1042c0f7	2026-03-20 15:05:13.204966
33	backward-compatible-index-on-prefixes	b480e99ed951e0900f033ec4eb34b5bdcb4e3d49	2026-03-20 15:05:13.210338
34	optimize-search-function-v1	ca80a3dc7bfef894df17108785ce29a7fc8ee456	2026-03-20 15:05:13.215786
35	add-insert-trigger-prefixes	458fe0ffd07ec53f5e3ce9df51bfdf4861929ccc	2026-03-20 15:05:13.221177
36	optimise-existing-functions	6ae5fca6af5c55abe95369cd4f93985d1814ca8f	2026-03-20 15:05:13.226599
37	add-bucket-name-length-trigger	3944135b4e3e8b22d6d4cbb568fe3b0b51df15c1	2026-03-20 15:05:13.232058
38	iceberg-catalog-flag-on-buckets	02716b81ceec9705aed84aa1501657095b32e5c5	2026-03-20 15:05:13.333316
39	add-search-v2-sort-support	6706c5f2928846abee18461279799ad12b279b78	2026-03-20 15:05:13.381148
40	fix-prefix-race-conditions-optimized	7ad69982ae2d372b21f48fc4829ae9752c518f6b	2026-03-20 15:05:13.387327
41	add-object-level-update-trigger	07fcf1a22165849b7a029deed059ffcde08d1ae0	2026-03-20 15:05:13.393155
42	rollback-prefix-triggers	771479077764adc09e2ea2043eb627503c034cd4	2026-03-20 15:05:13.398789
43	fix-object-level	84b35d6caca9d937478ad8a797491f38b8c2979f	2026-03-20 15:05:13.404491
44	vector-bucket-type	99c20c0ffd52bb1ff1f32fb992f3b351e3ef8fb3	2026-03-20 15:05:13.522125
45	vector-buckets	049e27196d77a7cb76497a85afae669d8b230953	2026-03-20 15:05:13.528882
46	buckets-objects-grants	fedeb96d60fefd8e02ab3ded9fbde05632f84aed	2026-03-20 15:05:13.545459
47	iceberg-table-metadata	649df56855c24d8b36dd4cc1aeb8251aa9ad42c2	2026-03-20 15:05:13.701178
48	iceberg-catalog-ids	e0e8b460c609b9999ccd0df9ad14294613eed939	2026-03-20 15:05:13.707208
49	buckets-objects-grants-postgres	072b1195d0d5a2f888af6b2302a1938dd94b8b3d	2026-03-20 15:05:13.87278
50	search-v2-optimised	6323ac4f850aa14e7387eb32102869578b5bd478	2026-03-20 15:05:13.889039
51	index-backward-compatible-search	2ee395d433f76e38bcd3856debaf6e0e5b674011	2026-03-20 15:05:14.833809
52	drop-not-used-indexes-and-functions	5cc44c8696749ac11dd0dc37f2a3802075f3a171	2026-03-20 15:05:14.836212
53	drop-index-lower-name	d0cb18777d9e2a98ebe0bc5cc7a42e57ebe41854	2026-03-20 15:05:14.851425
54	drop-index-object-level	6289e048b1472da17c31a7eba1ded625a6457e67	2026-03-20 15:05:14.854976
55	prevent-direct-deletes	262a4798d5e0f2e7c8970232e03ce8be695d5819	2026-03-20 15:05:14.857188
56	fix-optimized-search-function	cb58526ebc23048049fd5bf2fd148d18b04a2073	2026-03-20 15:05:14.863983
\.


--
-- Data for Name: objects; Type: TABLE DATA; Schema: storage; Owner: -
--

COPY storage.objects (id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata, version, owner_id, user_metadata) FROM stdin;
\.


--
-- Data for Name: s3_multipart_uploads; Type: TABLE DATA; Schema: storage; Owner: -
--

COPY storage.s3_multipart_uploads (id, in_progress_size, upload_signature, bucket_id, key, version, owner_id, created_at, user_metadata) FROM stdin;
\.


--
-- Data for Name: s3_multipart_uploads_parts; Type: TABLE DATA; Schema: storage; Owner: -
--

COPY storage.s3_multipart_uploads_parts (id, upload_id, size, part_number, bucket_id, key, etag, owner_id, version, created_at) FROM stdin;
\.


--
-- Data for Name: vector_indexes; Type: TABLE DATA; Schema: storage; Owner: -
--

COPY storage.vector_indexes (id, name, bucket_id, data_type, dimension, distance_metric, metadata_configuration, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: schema_migrations; Type: TABLE DATA; Schema: supabase_migrations; Owner: -
--

COPY supabase_migrations.schema_migrations (version, statements, name) FROM stdin;
20260321120000	{"-- Foundation schema for the AI dealership WhatsApp chatbot.\n-- Aligned to docs/system_design.md Phase 1 database design.\n\ncreate extension if not exists pgcrypto","create or replace function public.set_updated_at()\nreturns trigger\nlanguage plpgsql\nas $$\nbegin\n  new.updated_at = now();\n  return new;\nend;\n$$","create table if not exists public.app_users (\n  id uuid primary key references auth.users (id) on delete cascade,\n  full_name text,\n  role text not null default 'staff' check (role in ('admin', 'sales', 'manager', 'staff')),\n  phone text,\n  is_active boolean not null default true,\n  created_at timestamptz not null default now()\n)","create table if not exists public.leads (\n  id uuid primary key default gen_random_uuid(),\n  phone text not null unique,\n  customer_name text,\n  interested_model text,\n  fuel_type text,\n  transmission text,\n  exchange_required boolean,\n  lead_status text not null default 'new',\n  assigned_to uuid references public.app_users (id) on delete set null,\n  source text not null default 'whatsapp',\n  city text,\n  notes text,\n  created_at timestamptz not null default now(),\n  updated_at timestamptz not null default now()\n)","create table if not exists public.conversations (\n  id uuid primary key default gen_random_uuid(),\n  phone text not null unique,\n  lead_id uuid references public.leads (id) on delete set null,\n  current_state text not null default 'new',\n  current_step text,\n  last_message_at timestamptz,\n  is_open boolean not null default true,\n  created_at timestamptz not null default now(),\n  updated_at timestamptz not null default now()\n)","create table if not exists public.messages (\n  id uuid primary key default gen_random_uuid(),\n  conversation_id uuid not null references public.conversations (id) on delete cascade,\n  phone text not null,\n  direction text not null check (direction in ('inbound', 'outbound')),\n  message_type text not null default 'text',\n  content text,\n  raw_payload jsonb,\n  whatsapp_message_id text,\n  status text,\n  created_at timestamptz not null default now()\n)","create table if not exists public.variants (\n  id uuid primary key default gen_random_uuid(),\n  model text not null,\n  variant_name text not null,\n  fuel_type text not null,\n  transmission text not null,\n  ex_showroom_price numeric(12, 2) not null check (ex_showroom_price >= 0),\n  brochure_url text,\n  is_active boolean not null default true,\n  created_at timestamptz not null default now(),\n  updated_at timestamptz not null default now(),\n  unique (model, variant_name, fuel_type, transmission)\n)","create table if not exists public.pricing_rules (\n  id uuid primary key default gen_random_uuid(),\n  model text,\n  variant_id uuid references public.variants (id) on delete cascade,\n  rule_type text not null,\n  rule_name text not null,\n  value_type text not null check (value_type in ('fixed', 'percent')),\n  value numeric(12, 2) not null,\n  is_stackable boolean not null default false,\n  conditions jsonb,\n  is_active boolean not null default true,\n  created_at timestamptz not null default now(),\n  updated_at timestamptz not null default now(),\n  check (value >= 0),\n  check (model is not null or variant_id is not null)\n)","create table if not exists public.brochures (\n  id uuid primary key default gen_random_uuid(),\n  model text not null,\n  file_name text not null,\n  storage_path text not null,\n  public_url text,\n  version text,\n  is_active boolean not null default true,\n  uploaded_by uuid references public.app_users (id) on delete set null,\n  created_at timestamptz not null default now()\n)","create table if not exists public.campaign_templates (\n  id uuid primary key default gen_random_uuid(),\n  template_name text not null unique,\n  language_code text not null,\n  category text not null,\n  header_type text,\n  body_example text,\n  buttons jsonb,\n  is_active boolean not null default true,\n  created_at timestamptz not null default now()\n)","create table if not exists public.campaigns (\n  id uuid primary key default gen_random_uuid(),\n  name text not null,\n  template_id uuid references public.campaign_templates (id) on delete restrict,\n  status text not null default 'draft' check (status in ('draft', 'sending', 'sent', 'failed')),\n  recipient_source text not null,\n  payload jsonb,\n  created_by uuid references public.app_users (id) on delete set null,\n  created_at timestamptz not null default now(),\n  sent_at timestamptz\n)","create table if not exists public.campaign_recipients (\n  id uuid primary key default gen_random_uuid(),\n  campaign_id uuid not null references public.campaigns (id) on delete cascade,\n  phone text not null,\n  customer_name text,\n  variables jsonb,\n  send_status text not null default 'pending',\n  error_message text,\n  sent_at timestamptz,\n  delivered_at timestamptz,\n  created_at timestamptz not null default now()\n)","create index if not exists idx_app_users_role on public.app_users (role)","create index if not exists idx_app_users_phone on public.app_users (phone)","create index if not exists idx_leads_status on public.leads (lead_status)","create index if not exists idx_leads_assigned_to on public.leads (assigned_to)","create index if not exists idx_leads_interested_model on public.leads (interested_model)","create index if not exists idx_leads_created_at on public.leads (created_at desc)","create index if not exists idx_conversations_lead_id on public.conversations (lead_id)","create index if not exists idx_conversations_state_open on public.conversations (current_state, is_open)","create index if not exists idx_conversations_last_message_at on public.conversations (last_message_at desc)","create index if not exists idx_messages_conversation_id_created_at on public.messages (conversation_id, created_at desc)","create index if not exists idx_messages_phone on public.messages (phone)","create index if not exists idx_messages_whatsapp_message_id on public.messages (whatsapp_message_id)","create index if not exists idx_messages_direction on public.messages (direction)","create index if not exists idx_variants_model_active on public.variants (model, is_active)","create index if not exists idx_variants_filters on public.variants (model, fuel_type, transmission, is_active)","create index if not exists idx_pricing_rules_model_active on public.pricing_rules (model, is_active)","create index if not exists idx_pricing_rules_variant_active on public.pricing_rules (variant_id, is_active)","create index if not exists idx_pricing_rules_rule_type on public.pricing_rules (rule_type)","create index if not exists idx_brochures_model_active on public.brochures (model, is_active)","create index if not exists idx_campaign_templates_active on public.campaign_templates (is_active)","create index if not exists idx_campaigns_template_id on public.campaigns (template_id)","create index if not exists idx_campaigns_status on public.campaigns (status)","create index if not exists idx_campaigns_created_by on public.campaigns (created_by)","create index if not exists idx_campaigns_created_at on public.campaigns (created_at desc)","create index if not exists idx_campaign_recipients_campaign_id on public.campaign_recipients (campaign_id)","create index if not exists idx_campaign_recipients_send_status on public.campaign_recipients (send_status)","create index if not exists idx_campaign_recipients_phone on public.campaign_recipients (phone)","drop trigger if exists set_leads_updated_at on public.leads","create trigger set_leads_updated_at\nbefore update on public.leads\nfor each row\nexecute function public.set_updated_at()","drop trigger if exists set_conversations_updated_at on public.conversations","create trigger set_conversations_updated_at\nbefore update on public.conversations\nfor each row\nexecute function public.set_updated_at()","drop trigger if exists set_variants_updated_at on public.variants","create trigger set_variants_updated_at\nbefore update on public.variants\nfor each row\nexecute function public.set_updated_at()","drop trigger if exists set_pricing_rules_updated_at on public.pricing_rules","create trigger set_pricing_rules_updated_at\nbefore update on public.pricing_rules\nfor each row\nexecute function public.set_updated_at()"}	initial_foundation
20260321121000	{"-- Example seed data for local development and schema validation.\n-- This file is safe to re-run because inserts are keyed on stable unique combinations.\n\ninsert into public.variants (\n  model,\n  variant_name,\n  fuel_type,\n  transmission,\n  ex_showroom_price,\n  brochure_url,\n  is_active\n)\nvalues\n  (\n    'Hyundai Creta',\n    'S',\n    'Petrol',\n    'Manual',\n    1250000.00,\n    'https://example.com/brochures/hyundai-creta-s-petrol-manual.pdf',\n    true\n  ),\n  (\n    'Hyundai Creta',\n    'SX',\n    'Petrol',\n    'Automatic',\n    1575000.00,\n    'https://example.com/brochures/hyundai-creta-sx-petrol-automatic.pdf',\n    true\n  ),\n  (\n    'Kia Seltos',\n    'HTK Plus',\n    'Diesel',\n    'Manual',\n    1490000.00,\n    'https://example.com/brochures/kia-seltos-htk-plus-diesel-manual.pdf',\n    true\n  )\non conflict (model, variant_name, fuel_type, transmission) do update\nset\n  ex_showroom_price = excluded.ex_showroom_price,\n  brochure_url = excluded.brochure_url,\n  is_active = excluded.is_active","insert into public.pricing_rules (\n  model,\n  variant_id,\n  rule_type,\n  rule_name,\n  value_type,\n  value,\n  is_stackable,\n  conditions,\n  is_active\n)\nselect\n  'Hyundai Creta',\n  null,\n  'rto_percent',\n  'Creta Standard RTO',\n  'percent',\n  10.50,\n  false,\n  '{\\"city\\":\\"default\\"}'::jsonb,\n  true\nwhere not exists (\n  select 1\n  from public.pricing_rules\n  where model = 'Hyundai Creta'\n    and variant_id is null\n    and rule_type = 'rto_percent'\n    and rule_name = 'Creta Standard RTO'\n)","insert into public.pricing_rules (\n  model,\n  variant_id,\n  rule_type,\n  rule_name,\n  value_type,\n  value,\n  is_stackable,\n  conditions,\n  is_active\n)\nselect\n  'Hyundai Creta',\n  null,\n  'insurance_fixed',\n  'Creta Insurance Base',\n  'fixed',\n  45000.00,\n  false,\n  '{\\"provider\\":\\"default\\"}'::jsonb,\n  true\nwhere not exists (\n  select 1\n  from public.pricing_rules\n  where model = 'Hyundai Creta'\n    and variant_id is null\n    and rule_type = 'insurance_fixed'\n    and rule_name = 'Creta Insurance Base'\n)","insert into public.pricing_rules (\n  model,\n  variant_id,\n  rule_type,\n  rule_name,\n  value_type,\n  value,\n  is_stackable,\n  conditions,\n  is_active\n)\nselect\n  'Hyundai Creta',\n  null,\n  'exchange_bonus',\n  'Creta Exchange Bonus',\n  'fixed',\n  25000.00,\n  false,\n  '{\\"exchange_required\\":true}'::jsonb,\n  true\nwhere not exists (\n  select 1\n  from public.pricing_rules\n  where model = 'Hyundai Creta'\n    and variant_id is null\n    and rule_type = 'exchange_bonus'\n    and rule_name = 'Creta Exchange Bonus'\n)","insert into public.pricing_rules (\n  model,\n  variant_id,\n  rule_type,\n  rule_name,\n  value_type,\n  value,\n  is_stackable,\n  conditions,\n  is_active\n)\nselect\n  null,\n  v.id,\n  'handling_fixed',\n  'Seltos HTK Plus Handling',\n  'fixed',\n  12000.00,\n  false,\n  '{\\"location\\":\\"default\\"}'::jsonb,\n  true\nfrom public.variants v\nwhere v.model = 'Kia Seltos'\n  and v.variant_name = 'HTK Plus'\n  and v.fuel_type = 'Diesel'\n  and v.transmission = 'Manual'\n  and not exists (\n    select 1\n    from public.pricing_rules pr\n    where pr.variant_id = v.id\n      and pr.rule_type = 'handling_fixed'\n      and pr.rule_name = 'Seltos HTK Plus Handling'\n  )","insert into public.campaign_templates (\n  template_name,\n  language_code,\n  category,\n  header_type,\n  body_example,\n  buttons,\n  is_active\n)\nvalues (\n  'new_launch_followup',\n  'en',\n  'marketing',\n  'text',\n  'Hello {{1}}, check out our latest offers on {{2}}. Reply to get variant and on-road pricing details.',\n  '[{\\"type\\":\\"quick_reply\\",\\"text\\":\\"Show variants\\"},{\\"type\\":\\"quick_reply\\",\\"text\\":\\"Get pricing\\"}]'::jsonb,\n  true\n)\non conflict (template_name) do update\nset\n  language_code = excluded.language_code,\n  category = excluded.category,\n  header_type = excluded.header_type,\n  body_example = excluded.body_example,\n  buttons = excluded.buttons,\n  is_active = excluded.is_active"}	seed_examples
20260321132000	{"create unique index if not exists uq_messages_whatsapp_message_id\non public.messages (whatsapp_message_id)\nwhere whatsapp_message_id is not null"}	add_unique_whatsapp_message_id
20260321143000	{"alter table public.conversations\nadd column if not exists campaign_id uuid references public.campaigns (id) on delete set null","create index if not exists idx_conversations_campaign_id\non public.conversations (campaign_id)"}	add_campaign_id_to_conversations
20260322000000	{"-- Allow multiple conversations per phone number.\n-- The old UNIQUE constraint on phone prevented returning customers from starting fresh.\n-- We now use is_open to identify the active conversation.\n\nALTER TABLE public.conversations DROP CONSTRAINT IF EXISTS conversations_phone_key","-- Add a partial unique index: only one open conversation per phone at a time.\nCREATE UNIQUE INDEX IF NOT EXISTS uq_conversations_phone_open\n  ON public.conversations (phone)\n  WHERE (is_open = true)","-- Update findOrCreateConversationByPhone logic note:\n-- The Edge Function conversation-manager.ts uses upsert on phone with a unique constraint.\n-- After this migration, the upsert must change to:\n--   1. Try to find an existing OPEN conversation for this phone\n--   2. If none exists, insert a new one (is_open = true)\n-- This is handled in the next code change below."}	fix_conversation_uniqueness
20260322000001	{"ALTER TABLE public.leads ENABLE ROW LEVEL SECURITY","CREATE POLICY \\"Authenticated users can read leads\\"\n  ON public.leads FOR SELECT\n  TO authenticated\n  USING (auth.role() = 'authenticated')","CREATE POLICY \\"Authenticated users can insert leads\\"\n  ON public.leads FOR INSERT\n  TO authenticated\n  WITH CHECK (auth.role() = 'authenticated')","CREATE POLICY \\"Authenticated users can update leads\\"\n  ON public.leads FOR UPDATE\n  TO authenticated\n  USING (auth.role() = 'authenticated')\n  WITH CHECK (auth.role() = 'authenticated')","ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY","CREATE POLICY \\"Authenticated users can read conversations\\"\n  ON public.conversations FOR SELECT\n  TO authenticated\n  USING (auth.role() = 'authenticated')","CREATE POLICY \\"Authenticated users can insert conversations\\"\n  ON public.conversations FOR INSERT\n  TO authenticated\n  WITH CHECK (auth.role() = 'authenticated')","CREATE POLICY \\"Authenticated users can update conversations\\"\n  ON public.conversations FOR UPDATE\n  TO authenticated\n  USING (auth.role() = 'authenticated')\n  WITH CHECK (auth.role() = 'authenticated')","ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY","CREATE POLICY \\"Authenticated users can read messages\\"\n  ON public.messages FOR SELECT\n  TO authenticated\n  USING (auth.role() = 'authenticated')","CREATE POLICY \\"Authenticated users can insert messages\\"\n  ON public.messages FOR INSERT\n  TO authenticated\n  WITH CHECK (auth.role() = 'authenticated')","CREATE POLICY \\"Authenticated users can update messages\\"\n  ON public.messages FOR UPDATE\n  TO authenticated\n  USING (auth.role() = 'authenticated')\n  WITH CHECK (auth.role() = 'authenticated')","ALTER TABLE public.variants ENABLE ROW LEVEL SECURITY","CREATE POLICY \\"Authenticated users can read variants\\"\n  ON public.variants FOR SELECT\n  TO authenticated\n  USING (auth.role() = 'authenticated')","CREATE POLICY \\"Authenticated users can insert variants\\"\n  ON public.variants FOR INSERT\n  TO authenticated\n  WITH CHECK (auth.role() = 'authenticated')","CREATE POLICY \\"Authenticated users can update variants\\"\n  ON public.variants FOR UPDATE\n  TO authenticated\n  USING (auth.role() = 'authenticated')\n  WITH CHECK (auth.role() = 'authenticated')","CREATE POLICY \\"Authenticated users can delete variants\\"\n  ON public.variants FOR DELETE\n  TO authenticated\n  USING (auth.role() = 'authenticated')","ALTER TABLE public.campaigns ENABLE ROW LEVEL SECURITY","CREATE POLICY \\"Authenticated users can read campaigns\\"\n  ON public.campaigns FOR SELECT\n  TO authenticated\n  USING (auth.role() = 'authenticated')","CREATE POLICY \\"Authenticated users can insert campaigns\\"\n  ON public.campaigns FOR INSERT\n  TO authenticated\n  WITH CHECK (auth.role() = 'authenticated')","CREATE POLICY \\"Authenticated users can update campaigns\\"\n  ON public.campaigns FOR UPDATE\n  TO authenticated\n  USING (auth.role() = 'authenticated')\n  WITH CHECK (auth.role() = 'authenticated')","CREATE POLICY \\"Authenticated users can delete campaigns\\"\n  ON public.campaigns FOR DELETE\n  TO authenticated\n  USING (auth.role() = 'authenticated')","ALTER TABLE public.campaign_recipients ENABLE ROW LEVEL SECURITY","CREATE POLICY \\"Authenticated users can read campaign recipients\\"\n  ON public.campaign_recipients FOR SELECT\n  TO authenticated\n  USING (auth.role() = 'authenticated')","CREATE POLICY \\"Authenticated users can insert campaign recipients\\"\n  ON public.campaign_recipients FOR INSERT\n  TO authenticated\n  WITH CHECK (auth.role() = 'authenticated')","CREATE POLICY \\"Authenticated users can update campaign recipients\\"\n  ON public.campaign_recipients FOR UPDATE\n  TO authenticated\n  USING (auth.role() = 'authenticated')\n  WITH CHECK (auth.role() = 'authenticated')","CREATE POLICY \\"Authenticated users can delete campaign recipients\\"\n  ON public.campaign_recipients FOR DELETE\n  TO authenticated\n  USING (auth.role() = 'authenticated')","ALTER TABLE public.campaign_templates ENABLE ROW LEVEL SECURITY","CREATE POLICY \\"Authenticated users can read campaign templates\\"\n  ON public.campaign_templates FOR SELECT\n  TO authenticated\n  USING (auth.role() = 'authenticated')","CREATE POLICY \\"Authenticated users can insert campaign templates\\"\n  ON public.campaign_templates FOR INSERT\n  TO authenticated\n  WITH CHECK (auth.role() = 'authenticated')","CREATE POLICY \\"Authenticated users can update campaign templates\\"\n  ON public.campaign_templates FOR UPDATE\n  TO authenticated\n  USING (auth.role() = 'authenticated')\n  WITH CHECK (auth.role() = 'authenticated')","CREATE POLICY \\"Authenticated users can delete campaign templates\\"\n  ON public.campaign_templates FOR DELETE\n  TO authenticated\n  USING (auth.role() = 'authenticated')","ALTER TABLE public.app_users ENABLE ROW LEVEL SECURITY","CREATE POLICY \\"Authenticated users can read app users\\"\n  ON public.app_users FOR SELECT\n  TO authenticated\n  USING (auth.role() = 'authenticated')","CREATE POLICY \\"Authenticated users can insert app users\\"\n  ON public.app_users FOR INSERT\n  TO authenticated\n  WITH CHECK (auth.role() = 'authenticated')","CREATE POLICY \\"Authenticated users can update app users\\"\n  ON public.app_users FOR UPDATE\n  TO authenticated\n  USING (auth.role() = 'authenticated')\n  WITH CHECK (auth.role() = 'authenticated')","CREATE POLICY \\"Authenticated users can delete app users\\"\n  ON public.app_users FOR DELETE\n  TO authenticated\n  USING (auth.role() = 'authenticated')"}	rls_policies
\.


--
-- Data for Name: secrets; Type: TABLE DATA; Schema: vault; Owner: -
--

COPY vault.secrets (id, name, description, secret, key_id, nonce, created_at, updated_at) FROM stdin;
\.


--
-- Name: refresh_tokens_id_seq; Type: SEQUENCE SET; Schema: auth; Owner: -
--

SELECT pg_catalog.setval('auth.refresh_tokens_id_seq', 1, false);


--
-- Name: subscription_id_seq; Type: SEQUENCE SET; Schema: realtime; Owner: -
--

SELECT pg_catalog.setval('realtime.subscription_id_seq', 1, false);


--
-- Name: mfa_amr_claims amr_id_pk; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_amr_claims
    ADD CONSTRAINT amr_id_pk PRIMARY KEY (id);


--
-- Name: audit_log_entries audit_log_entries_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.audit_log_entries
    ADD CONSTRAINT audit_log_entries_pkey PRIMARY KEY (id);


--
-- Name: custom_oauth_providers custom_oauth_providers_identifier_key; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.custom_oauth_providers
    ADD CONSTRAINT custom_oauth_providers_identifier_key UNIQUE (identifier);


--
-- Name: custom_oauth_providers custom_oauth_providers_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.custom_oauth_providers
    ADD CONSTRAINT custom_oauth_providers_pkey PRIMARY KEY (id);


--
-- Name: flow_state flow_state_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.flow_state
    ADD CONSTRAINT flow_state_pkey PRIMARY KEY (id);


--
-- Name: identities identities_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.identities
    ADD CONSTRAINT identities_pkey PRIMARY KEY (id);


--
-- Name: identities identities_provider_id_provider_unique; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.identities
    ADD CONSTRAINT identities_provider_id_provider_unique UNIQUE (provider_id, provider);


--
-- Name: instances instances_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.instances
    ADD CONSTRAINT instances_pkey PRIMARY KEY (id);


--
-- Name: mfa_amr_claims mfa_amr_claims_session_id_authentication_method_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_amr_claims
    ADD CONSTRAINT mfa_amr_claims_session_id_authentication_method_pkey UNIQUE (session_id, authentication_method);


--
-- Name: mfa_challenges mfa_challenges_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_challenges
    ADD CONSTRAINT mfa_challenges_pkey PRIMARY KEY (id);


--
-- Name: mfa_factors mfa_factors_last_challenged_at_key; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_factors
    ADD CONSTRAINT mfa_factors_last_challenged_at_key UNIQUE (last_challenged_at);


--
-- Name: mfa_factors mfa_factors_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_factors
    ADD CONSTRAINT mfa_factors_pkey PRIMARY KEY (id);


--
-- Name: oauth_authorizations oauth_authorizations_authorization_code_key; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.oauth_authorizations
    ADD CONSTRAINT oauth_authorizations_authorization_code_key UNIQUE (authorization_code);


--
-- Name: oauth_authorizations oauth_authorizations_authorization_id_key; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.oauth_authorizations
    ADD CONSTRAINT oauth_authorizations_authorization_id_key UNIQUE (authorization_id);


--
-- Name: oauth_authorizations oauth_authorizations_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.oauth_authorizations
    ADD CONSTRAINT oauth_authorizations_pkey PRIMARY KEY (id);


--
-- Name: oauth_client_states oauth_client_states_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.oauth_client_states
    ADD CONSTRAINT oauth_client_states_pkey PRIMARY KEY (id);


--
-- Name: oauth_clients oauth_clients_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.oauth_clients
    ADD CONSTRAINT oauth_clients_pkey PRIMARY KEY (id);


--
-- Name: oauth_consents oauth_consents_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.oauth_consents
    ADD CONSTRAINT oauth_consents_pkey PRIMARY KEY (id);


--
-- Name: oauth_consents oauth_consents_user_client_unique; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.oauth_consents
    ADD CONSTRAINT oauth_consents_user_client_unique UNIQUE (user_id, client_id);


--
-- Name: one_time_tokens one_time_tokens_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.one_time_tokens
    ADD CONSTRAINT one_time_tokens_pkey PRIMARY KEY (id);


--
-- Name: refresh_tokens refresh_tokens_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.refresh_tokens
    ADD CONSTRAINT refresh_tokens_pkey PRIMARY KEY (id);


--
-- Name: refresh_tokens refresh_tokens_token_unique; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.refresh_tokens
    ADD CONSTRAINT refresh_tokens_token_unique UNIQUE (token);


--
-- Name: saml_providers saml_providers_entity_id_key; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.saml_providers
    ADD CONSTRAINT saml_providers_entity_id_key UNIQUE (entity_id);


--
-- Name: saml_providers saml_providers_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.saml_providers
    ADD CONSTRAINT saml_providers_pkey PRIMARY KEY (id);


--
-- Name: saml_relay_states saml_relay_states_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.saml_relay_states
    ADD CONSTRAINT saml_relay_states_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: sessions sessions_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.sessions
    ADD CONSTRAINT sessions_pkey PRIMARY KEY (id);


--
-- Name: sso_domains sso_domains_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.sso_domains
    ADD CONSTRAINT sso_domains_pkey PRIMARY KEY (id);


--
-- Name: sso_providers sso_providers_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.sso_providers
    ADD CONSTRAINT sso_providers_pkey PRIMARY KEY (id);


--
-- Name: users users_phone_key; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.users
    ADD CONSTRAINT users_phone_key UNIQUE (phone);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: webauthn_challenges webauthn_challenges_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.webauthn_challenges
    ADD CONSTRAINT webauthn_challenges_pkey PRIMARY KEY (id);


--
-- Name: webauthn_credentials webauthn_credentials_pkey; Type: CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.webauthn_credentials
    ADD CONSTRAINT webauthn_credentials_pkey PRIMARY KEY (id);


--
-- Name: app_users app_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.app_users
    ADD CONSTRAINT app_users_pkey PRIMARY KEY (id);


--
-- Name: brochures brochures_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.brochures
    ADD CONSTRAINT brochures_pkey PRIMARY KEY (id);


--
-- Name: campaign_recipients campaign_recipients_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.campaign_recipients
    ADD CONSTRAINT campaign_recipients_pkey PRIMARY KEY (id);


--
-- Name: campaign_templates campaign_templates_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.campaign_templates
    ADD CONSTRAINT campaign_templates_pkey PRIMARY KEY (id);


--
-- Name: campaign_templates campaign_templates_template_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.campaign_templates
    ADD CONSTRAINT campaign_templates_template_name_key UNIQUE (template_name);


--
-- Name: campaigns campaigns_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.campaigns
    ADD CONSTRAINT campaigns_pkey PRIMARY KEY (id);


--
-- Name: conversations conversations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversations
    ADD CONSTRAINT conversations_pkey PRIMARY KEY (id);


--
-- Name: leads leads_phone_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leads
    ADD CONSTRAINT leads_phone_key UNIQUE (phone);


--
-- Name: leads leads_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leads
    ADD CONSTRAINT leads_pkey PRIMARY KEY (id);


--
-- Name: messages messages_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_pkey PRIMARY KEY (id);


--
-- Name: pricing_rules pricing_rules_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pricing_rules
    ADD CONSTRAINT pricing_rules_pkey PRIMARY KEY (id);


--
-- Name: variants variants_model_variant_name_fuel_type_transmission_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.variants
    ADD CONSTRAINT variants_model_variant_name_fuel_type_transmission_key UNIQUE (model, variant_name, fuel_type, transmission);


--
-- Name: variants variants_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.variants
    ADD CONSTRAINT variants_pkey PRIMARY KEY (id);


--
-- Name: messages messages_pkey; Type: CONSTRAINT; Schema: realtime; Owner: -
--

ALTER TABLE ONLY realtime.messages
    ADD CONSTRAINT messages_pkey PRIMARY KEY (id, inserted_at);


--
-- Name: subscription pk_subscription; Type: CONSTRAINT; Schema: realtime; Owner: -
--

ALTER TABLE ONLY realtime.subscription
    ADD CONSTRAINT pk_subscription PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: realtime; Owner: -
--

ALTER TABLE ONLY realtime.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: buckets_analytics buckets_analytics_pkey; Type: CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.buckets_analytics
    ADD CONSTRAINT buckets_analytics_pkey PRIMARY KEY (id);


--
-- Name: buckets buckets_pkey; Type: CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.buckets
    ADD CONSTRAINT buckets_pkey PRIMARY KEY (id);


--
-- Name: buckets_vectors buckets_vectors_pkey; Type: CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.buckets_vectors
    ADD CONSTRAINT buckets_vectors_pkey PRIMARY KEY (id);


--
-- Name: migrations migrations_name_key; Type: CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.migrations
    ADD CONSTRAINT migrations_name_key UNIQUE (name);


--
-- Name: migrations migrations_pkey; Type: CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.migrations
    ADD CONSTRAINT migrations_pkey PRIMARY KEY (id);


--
-- Name: objects objects_pkey; Type: CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.objects
    ADD CONSTRAINT objects_pkey PRIMARY KEY (id);


--
-- Name: s3_multipart_uploads_parts s3_multipart_uploads_parts_pkey; Type: CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.s3_multipart_uploads_parts
    ADD CONSTRAINT s3_multipart_uploads_parts_pkey PRIMARY KEY (id);


--
-- Name: s3_multipart_uploads s3_multipart_uploads_pkey; Type: CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.s3_multipart_uploads
    ADD CONSTRAINT s3_multipart_uploads_pkey PRIMARY KEY (id);


--
-- Name: vector_indexes vector_indexes_pkey; Type: CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.vector_indexes
    ADD CONSTRAINT vector_indexes_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: supabase_migrations; Owner: -
--

ALTER TABLE ONLY supabase_migrations.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: audit_logs_instance_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX audit_logs_instance_id_idx ON auth.audit_log_entries USING btree (instance_id);


--
-- Name: confirmation_token_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX confirmation_token_idx ON auth.users USING btree (confirmation_token) WHERE ((confirmation_token)::text !~ '^[0-9 ]*$'::text);


--
-- Name: custom_oauth_providers_created_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX custom_oauth_providers_created_at_idx ON auth.custom_oauth_providers USING btree (created_at);


--
-- Name: custom_oauth_providers_enabled_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX custom_oauth_providers_enabled_idx ON auth.custom_oauth_providers USING btree (enabled);


--
-- Name: custom_oauth_providers_identifier_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX custom_oauth_providers_identifier_idx ON auth.custom_oauth_providers USING btree (identifier);


--
-- Name: custom_oauth_providers_provider_type_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX custom_oauth_providers_provider_type_idx ON auth.custom_oauth_providers USING btree (provider_type);


--
-- Name: email_change_token_current_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX email_change_token_current_idx ON auth.users USING btree (email_change_token_current) WHERE ((email_change_token_current)::text !~ '^[0-9 ]*$'::text);


--
-- Name: email_change_token_new_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX email_change_token_new_idx ON auth.users USING btree (email_change_token_new) WHERE ((email_change_token_new)::text !~ '^[0-9 ]*$'::text);


--
-- Name: factor_id_created_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX factor_id_created_at_idx ON auth.mfa_factors USING btree (user_id, created_at);


--
-- Name: flow_state_created_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX flow_state_created_at_idx ON auth.flow_state USING btree (created_at DESC);


--
-- Name: identities_email_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX identities_email_idx ON auth.identities USING btree (email text_pattern_ops);


--
-- Name: INDEX identities_email_idx; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON INDEX auth.identities_email_idx IS 'Auth: Ensures indexed queries on the email column';


--
-- Name: identities_user_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX identities_user_id_idx ON auth.identities USING btree (user_id);


--
-- Name: idx_auth_code; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX idx_auth_code ON auth.flow_state USING btree (auth_code);


--
-- Name: idx_oauth_client_states_created_at; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX idx_oauth_client_states_created_at ON auth.oauth_client_states USING btree (created_at);


--
-- Name: idx_user_id_auth_method; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX idx_user_id_auth_method ON auth.flow_state USING btree (user_id, authentication_method);


--
-- Name: mfa_challenge_created_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX mfa_challenge_created_at_idx ON auth.mfa_challenges USING btree (created_at DESC);


--
-- Name: mfa_factors_user_friendly_name_unique; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX mfa_factors_user_friendly_name_unique ON auth.mfa_factors USING btree (friendly_name, user_id) WHERE (TRIM(BOTH FROM friendly_name) <> ''::text);


--
-- Name: mfa_factors_user_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX mfa_factors_user_id_idx ON auth.mfa_factors USING btree (user_id);


--
-- Name: oauth_auth_pending_exp_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX oauth_auth_pending_exp_idx ON auth.oauth_authorizations USING btree (expires_at) WHERE (status = 'pending'::auth.oauth_authorization_status);


--
-- Name: oauth_clients_deleted_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX oauth_clients_deleted_at_idx ON auth.oauth_clients USING btree (deleted_at);


--
-- Name: oauth_consents_active_client_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX oauth_consents_active_client_idx ON auth.oauth_consents USING btree (client_id) WHERE (revoked_at IS NULL);


--
-- Name: oauth_consents_active_user_client_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX oauth_consents_active_user_client_idx ON auth.oauth_consents USING btree (user_id, client_id) WHERE (revoked_at IS NULL);


--
-- Name: oauth_consents_user_order_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX oauth_consents_user_order_idx ON auth.oauth_consents USING btree (user_id, granted_at DESC);


--
-- Name: one_time_tokens_relates_to_hash_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX one_time_tokens_relates_to_hash_idx ON auth.one_time_tokens USING hash (relates_to);


--
-- Name: one_time_tokens_token_hash_hash_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX one_time_tokens_token_hash_hash_idx ON auth.one_time_tokens USING hash (token_hash);


--
-- Name: one_time_tokens_user_id_token_type_key; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX one_time_tokens_user_id_token_type_key ON auth.one_time_tokens USING btree (user_id, token_type);


--
-- Name: reauthentication_token_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX reauthentication_token_idx ON auth.users USING btree (reauthentication_token) WHERE ((reauthentication_token)::text !~ '^[0-9 ]*$'::text);


--
-- Name: recovery_token_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX recovery_token_idx ON auth.users USING btree (recovery_token) WHERE ((recovery_token)::text !~ '^[0-9 ]*$'::text);


--
-- Name: refresh_tokens_instance_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX refresh_tokens_instance_id_idx ON auth.refresh_tokens USING btree (instance_id);


--
-- Name: refresh_tokens_instance_id_user_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX refresh_tokens_instance_id_user_id_idx ON auth.refresh_tokens USING btree (instance_id, user_id);


--
-- Name: refresh_tokens_parent_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX refresh_tokens_parent_idx ON auth.refresh_tokens USING btree (parent);


--
-- Name: refresh_tokens_session_id_revoked_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX refresh_tokens_session_id_revoked_idx ON auth.refresh_tokens USING btree (session_id, revoked);


--
-- Name: refresh_tokens_updated_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX refresh_tokens_updated_at_idx ON auth.refresh_tokens USING btree (updated_at DESC);


--
-- Name: saml_providers_sso_provider_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX saml_providers_sso_provider_id_idx ON auth.saml_providers USING btree (sso_provider_id);


--
-- Name: saml_relay_states_created_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX saml_relay_states_created_at_idx ON auth.saml_relay_states USING btree (created_at DESC);


--
-- Name: saml_relay_states_for_email_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX saml_relay_states_for_email_idx ON auth.saml_relay_states USING btree (for_email);


--
-- Name: saml_relay_states_sso_provider_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX saml_relay_states_sso_provider_id_idx ON auth.saml_relay_states USING btree (sso_provider_id);


--
-- Name: sessions_not_after_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX sessions_not_after_idx ON auth.sessions USING btree (not_after DESC);


--
-- Name: sessions_oauth_client_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX sessions_oauth_client_id_idx ON auth.sessions USING btree (oauth_client_id);


--
-- Name: sessions_user_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX sessions_user_id_idx ON auth.sessions USING btree (user_id);


--
-- Name: sso_domains_domain_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX sso_domains_domain_idx ON auth.sso_domains USING btree (lower(domain));


--
-- Name: sso_domains_sso_provider_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX sso_domains_sso_provider_id_idx ON auth.sso_domains USING btree (sso_provider_id);


--
-- Name: sso_providers_resource_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX sso_providers_resource_id_idx ON auth.sso_providers USING btree (lower(resource_id));


--
-- Name: sso_providers_resource_id_pattern_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX sso_providers_resource_id_pattern_idx ON auth.sso_providers USING btree (resource_id text_pattern_ops);


--
-- Name: unique_phone_factor_per_user; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX unique_phone_factor_per_user ON auth.mfa_factors USING btree (user_id, phone);


--
-- Name: user_id_created_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX user_id_created_at_idx ON auth.sessions USING btree (user_id, created_at);


--
-- Name: users_email_partial_key; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX users_email_partial_key ON auth.users USING btree (email) WHERE (is_sso_user = false);


--
-- Name: INDEX users_email_partial_key; Type: COMMENT; Schema: auth; Owner: -
--

COMMENT ON INDEX auth.users_email_partial_key IS 'Auth: A partial unique index that applies only when is_sso_user is false';


--
-- Name: users_instance_id_email_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX users_instance_id_email_idx ON auth.users USING btree (instance_id, lower((email)::text));


--
-- Name: users_instance_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX users_instance_id_idx ON auth.users USING btree (instance_id);


--
-- Name: users_is_anonymous_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX users_is_anonymous_idx ON auth.users USING btree (is_anonymous);


--
-- Name: webauthn_challenges_expires_at_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX webauthn_challenges_expires_at_idx ON auth.webauthn_challenges USING btree (expires_at);


--
-- Name: webauthn_challenges_user_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX webauthn_challenges_user_id_idx ON auth.webauthn_challenges USING btree (user_id);


--
-- Name: webauthn_credentials_credential_id_key; Type: INDEX; Schema: auth; Owner: -
--

CREATE UNIQUE INDEX webauthn_credentials_credential_id_key ON auth.webauthn_credentials USING btree (credential_id);


--
-- Name: webauthn_credentials_user_id_idx; Type: INDEX; Schema: auth; Owner: -
--

CREATE INDEX webauthn_credentials_user_id_idx ON auth.webauthn_credentials USING btree (user_id);


--
-- Name: idx_app_users_phone; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_app_users_phone ON public.app_users USING btree (phone);


--
-- Name: idx_app_users_role; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_app_users_role ON public.app_users USING btree (role);


--
-- Name: idx_brochures_model_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_brochures_model_active ON public.brochures USING btree (model, is_active);


--
-- Name: idx_campaign_recipients_campaign_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_campaign_recipients_campaign_id ON public.campaign_recipients USING btree (campaign_id);


--
-- Name: idx_campaign_recipients_phone; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_campaign_recipients_phone ON public.campaign_recipients USING btree (phone);


--
-- Name: idx_campaign_recipients_send_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_campaign_recipients_send_status ON public.campaign_recipients USING btree (send_status);


--
-- Name: idx_campaign_templates_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_campaign_templates_active ON public.campaign_templates USING btree (is_active);


--
-- Name: idx_campaigns_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_campaigns_created_at ON public.campaigns USING btree (created_at DESC);


--
-- Name: idx_campaigns_created_by; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_campaigns_created_by ON public.campaigns USING btree (created_by);


--
-- Name: idx_campaigns_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_campaigns_status ON public.campaigns USING btree (status);


--
-- Name: idx_campaigns_template_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_campaigns_template_id ON public.campaigns USING btree (template_id);


--
-- Name: idx_conversations_campaign_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_conversations_campaign_id ON public.conversations USING btree (campaign_id);


--
-- Name: idx_conversations_last_message_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_conversations_last_message_at ON public.conversations USING btree (last_message_at DESC);


--
-- Name: idx_conversations_lead_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_conversations_lead_id ON public.conversations USING btree (lead_id);


--
-- Name: idx_conversations_state_open; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_conversations_state_open ON public.conversations USING btree (current_state, is_open);


--
-- Name: idx_leads_assigned_to; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_leads_assigned_to ON public.leads USING btree (assigned_to);


--
-- Name: idx_leads_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_leads_created_at ON public.leads USING btree (created_at DESC);


--
-- Name: idx_leads_interested_model; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_leads_interested_model ON public.leads USING btree (interested_model);


--
-- Name: idx_leads_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_leads_status ON public.leads USING btree (lead_status);


--
-- Name: idx_messages_conversation_id_created_at; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_messages_conversation_id_created_at ON public.messages USING btree (conversation_id, created_at DESC);


--
-- Name: idx_messages_direction; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_messages_direction ON public.messages USING btree (direction);


--
-- Name: idx_messages_phone; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_messages_phone ON public.messages USING btree (phone);


--
-- Name: idx_messages_whatsapp_message_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_messages_whatsapp_message_id ON public.messages USING btree (whatsapp_message_id);


--
-- Name: idx_pricing_rules_model_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pricing_rules_model_active ON public.pricing_rules USING btree (model, is_active);


--
-- Name: idx_pricing_rules_rule_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pricing_rules_rule_type ON public.pricing_rules USING btree (rule_type);


--
-- Name: idx_pricing_rules_variant_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_pricing_rules_variant_active ON public.pricing_rules USING btree (variant_id, is_active);


--
-- Name: idx_variants_filters; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_variants_filters ON public.variants USING btree (model, fuel_type, transmission, is_active);


--
-- Name: idx_variants_model_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_variants_model_active ON public.variants USING btree (model, is_active);


--
-- Name: uq_conversations_phone_open; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_conversations_phone_open ON public.conversations USING btree (phone) WHERE (is_open = true);


--
-- Name: uq_messages_whatsapp_message_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX uq_messages_whatsapp_message_id ON public.messages USING btree (whatsapp_message_id) WHERE (whatsapp_message_id IS NOT NULL);


--
-- Name: ix_realtime_subscription_entity; Type: INDEX; Schema: realtime; Owner: -
--

CREATE INDEX ix_realtime_subscription_entity ON realtime.subscription USING btree (entity);


--
-- Name: messages_inserted_at_topic_index; Type: INDEX; Schema: realtime; Owner: -
--

CREATE INDEX messages_inserted_at_topic_index ON ONLY realtime.messages USING btree (inserted_at DESC, topic) WHERE ((extension = 'broadcast'::text) AND (private IS TRUE));


--
-- Name: subscription_subscription_id_entity_filters_action_filter_key; Type: INDEX; Schema: realtime; Owner: -
--

CREATE UNIQUE INDEX subscription_subscription_id_entity_filters_action_filter_key ON realtime.subscription USING btree (subscription_id, entity, filters, action_filter);


--
-- Name: bname; Type: INDEX; Schema: storage; Owner: -
--

CREATE UNIQUE INDEX bname ON storage.buckets USING btree (name);


--
-- Name: bucketid_objname; Type: INDEX; Schema: storage; Owner: -
--

CREATE UNIQUE INDEX bucketid_objname ON storage.objects USING btree (bucket_id, name);


--
-- Name: buckets_analytics_unique_name_idx; Type: INDEX; Schema: storage; Owner: -
--

CREATE UNIQUE INDEX buckets_analytics_unique_name_idx ON storage.buckets_analytics USING btree (name) WHERE (deleted_at IS NULL);


--
-- Name: idx_multipart_uploads_list; Type: INDEX; Schema: storage; Owner: -
--

CREATE INDEX idx_multipart_uploads_list ON storage.s3_multipart_uploads USING btree (bucket_id, key, created_at);


--
-- Name: idx_objects_bucket_id_name; Type: INDEX; Schema: storage; Owner: -
--

CREATE INDEX idx_objects_bucket_id_name ON storage.objects USING btree (bucket_id, name COLLATE "C");


--
-- Name: idx_objects_bucket_id_name_lower; Type: INDEX; Schema: storage; Owner: -
--

CREATE INDEX idx_objects_bucket_id_name_lower ON storage.objects USING btree (bucket_id, lower(name) COLLATE "C");


--
-- Name: name_prefix_search; Type: INDEX; Schema: storage; Owner: -
--

CREATE INDEX name_prefix_search ON storage.objects USING btree (name text_pattern_ops);


--
-- Name: vector_indexes_name_bucket_id_idx; Type: INDEX; Schema: storage; Owner: -
--

CREATE UNIQUE INDEX vector_indexes_name_bucket_id_idx ON storage.vector_indexes USING btree (name, bucket_id);


--
-- Name: conversations set_conversations_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER set_conversations_updated_at BEFORE UPDATE ON public.conversations FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: leads set_leads_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER set_leads_updated_at BEFORE UPDATE ON public.leads FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: pricing_rules set_pricing_rules_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER set_pricing_rules_updated_at BEFORE UPDATE ON public.pricing_rules FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: variants set_variants_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER set_variants_updated_at BEFORE UPDATE ON public.variants FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: subscription tr_check_filters; Type: TRIGGER; Schema: realtime; Owner: -
--

CREATE TRIGGER tr_check_filters BEFORE INSERT OR UPDATE ON realtime.subscription FOR EACH ROW EXECUTE FUNCTION realtime.subscription_check_filters();


--
-- Name: buckets enforce_bucket_name_length_trigger; Type: TRIGGER; Schema: storage; Owner: -
--

CREATE TRIGGER enforce_bucket_name_length_trigger BEFORE INSERT OR UPDATE OF name ON storage.buckets FOR EACH ROW EXECUTE FUNCTION storage.enforce_bucket_name_length();


--
-- Name: buckets protect_buckets_delete; Type: TRIGGER; Schema: storage; Owner: -
--

CREATE TRIGGER protect_buckets_delete BEFORE DELETE ON storage.buckets FOR EACH STATEMENT EXECUTE FUNCTION storage.protect_delete();


--
-- Name: objects protect_objects_delete; Type: TRIGGER; Schema: storage; Owner: -
--

CREATE TRIGGER protect_objects_delete BEFORE DELETE ON storage.objects FOR EACH STATEMENT EXECUTE FUNCTION storage.protect_delete();


--
-- Name: objects update_objects_updated_at; Type: TRIGGER; Schema: storage; Owner: -
--

CREATE TRIGGER update_objects_updated_at BEFORE UPDATE ON storage.objects FOR EACH ROW EXECUTE FUNCTION storage.update_updated_at_column();


--
-- Name: identities identities_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.identities
    ADD CONSTRAINT identities_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: mfa_amr_claims mfa_amr_claims_session_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_amr_claims
    ADD CONSTRAINT mfa_amr_claims_session_id_fkey FOREIGN KEY (session_id) REFERENCES auth.sessions(id) ON DELETE CASCADE;


--
-- Name: mfa_challenges mfa_challenges_auth_factor_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_challenges
    ADD CONSTRAINT mfa_challenges_auth_factor_id_fkey FOREIGN KEY (factor_id) REFERENCES auth.mfa_factors(id) ON DELETE CASCADE;


--
-- Name: mfa_factors mfa_factors_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.mfa_factors
    ADD CONSTRAINT mfa_factors_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: oauth_authorizations oauth_authorizations_client_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.oauth_authorizations
    ADD CONSTRAINT oauth_authorizations_client_id_fkey FOREIGN KEY (client_id) REFERENCES auth.oauth_clients(id) ON DELETE CASCADE;


--
-- Name: oauth_authorizations oauth_authorizations_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.oauth_authorizations
    ADD CONSTRAINT oauth_authorizations_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: oauth_consents oauth_consents_client_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.oauth_consents
    ADD CONSTRAINT oauth_consents_client_id_fkey FOREIGN KEY (client_id) REFERENCES auth.oauth_clients(id) ON DELETE CASCADE;


--
-- Name: oauth_consents oauth_consents_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.oauth_consents
    ADD CONSTRAINT oauth_consents_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: one_time_tokens one_time_tokens_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.one_time_tokens
    ADD CONSTRAINT one_time_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: refresh_tokens refresh_tokens_session_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.refresh_tokens
    ADD CONSTRAINT refresh_tokens_session_id_fkey FOREIGN KEY (session_id) REFERENCES auth.sessions(id) ON DELETE CASCADE;


--
-- Name: saml_providers saml_providers_sso_provider_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.saml_providers
    ADD CONSTRAINT saml_providers_sso_provider_id_fkey FOREIGN KEY (sso_provider_id) REFERENCES auth.sso_providers(id) ON DELETE CASCADE;


--
-- Name: saml_relay_states saml_relay_states_flow_state_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.saml_relay_states
    ADD CONSTRAINT saml_relay_states_flow_state_id_fkey FOREIGN KEY (flow_state_id) REFERENCES auth.flow_state(id) ON DELETE CASCADE;


--
-- Name: saml_relay_states saml_relay_states_sso_provider_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.saml_relay_states
    ADD CONSTRAINT saml_relay_states_sso_provider_id_fkey FOREIGN KEY (sso_provider_id) REFERENCES auth.sso_providers(id) ON DELETE CASCADE;


--
-- Name: sessions sessions_oauth_client_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.sessions
    ADD CONSTRAINT sessions_oauth_client_id_fkey FOREIGN KEY (oauth_client_id) REFERENCES auth.oauth_clients(id) ON DELETE CASCADE;


--
-- Name: sessions sessions_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.sessions
    ADD CONSTRAINT sessions_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: sso_domains sso_domains_sso_provider_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.sso_domains
    ADD CONSTRAINT sso_domains_sso_provider_id_fkey FOREIGN KEY (sso_provider_id) REFERENCES auth.sso_providers(id) ON DELETE CASCADE;


--
-- Name: webauthn_challenges webauthn_challenges_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.webauthn_challenges
    ADD CONSTRAINT webauthn_challenges_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: webauthn_credentials webauthn_credentials_user_id_fkey; Type: FK CONSTRAINT; Schema: auth; Owner: -
--

ALTER TABLE ONLY auth.webauthn_credentials
    ADD CONSTRAINT webauthn_credentials_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: app_users app_users_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.app_users
    ADD CONSTRAINT app_users_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;


--
-- Name: brochures brochures_uploaded_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.brochures
    ADD CONSTRAINT brochures_uploaded_by_fkey FOREIGN KEY (uploaded_by) REFERENCES public.app_users(id) ON DELETE SET NULL;


--
-- Name: campaign_recipients campaign_recipients_campaign_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.campaign_recipients
    ADD CONSTRAINT campaign_recipients_campaign_id_fkey FOREIGN KEY (campaign_id) REFERENCES public.campaigns(id) ON DELETE CASCADE;


--
-- Name: campaigns campaigns_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.campaigns
    ADD CONSTRAINT campaigns_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.app_users(id) ON DELETE SET NULL;


--
-- Name: campaigns campaigns_template_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.campaigns
    ADD CONSTRAINT campaigns_template_id_fkey FOREIGN KEY (template_id) REFERENCES public.campaign_templates(id) ON DELETE RESTRICT;


--
-- Name: conversations conversations_campaign_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversations
    ADD CONSTRAINT conversations_campaign_id_fkey FOREIGN KEY (campaign_id) REFERENCES public.campaigns(id) ON DELETE SET NULL;


--
-- Name: conversations conversations_lead_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conversations
    ADD CONSTRAINT conversations_lead_id_fkey FOREIGN KEY (lead_id) REFERENCES public.leads(id) ON DELETE SET NULL;


--
-- Name: leads leads_assigned_to_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.leads
    ADD CONSTRAINT leads_assigned_to_fkey FOREIGN KEY (assigned_to) REFERENCES public.app_users(id) ON DELETE SET NULL;


--
-- Name: messages messages_conversation_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.messages
    ADD CONSTRAINT messages_conversation_id_fkey FOREIGN KEY (conversation_id) REFERENCES public.conversations(id) ON DELETE CASCADE;


--
-- Name: pricing_rules pricing_rules_variant_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pricing_rules
    ADD CONSTRAINT pricing_rules_variant_id_fkey FOREIGN KEY (variant_id) REFERENCES public.variants(id) ON DELETE CASCADE;


--
-- Name: objects objects_bucketId_fkey; Type: FK CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.objects
    ADD CONSTRAINT "objects_bucketId_fkey" FOREIGN KEY (bucket_id) REFERENCES storage.buckets(id);


--
-- Name: s3_multipart_uploads s3_multipart_uploads_bucket_id_fkey; Type: FK CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.s3_multipart_uploads
    ADD CONSTRAINT s3_multipart_uploads_bucket_id_fkey FOREIGN KEY (bucket_id) REFERENCES storage.buckets(id);


--
-- Name: s3_multipart_uploads_parts s3_multipart_uploads_parts_bucket_id_fkey; Type: FK CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.s3_multipart_uploads_parts
    ADD CONSTRAINT s3_multipart_uploads_parts_bucket_id_fkey FOREIGN KEY (bucket_id) REFERENCES storage.buckets(id);


--
-- Name: s3_multipart_uploads_parts s3_multipart_uploads_parts_upload_id_fkey; Type: FK CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.s3_multipart_uploads_parts
    ADD CONSTRAINT s3_multipart_uploads_parts_upload_id_fkey FOREIGN KEY (upload_id) REFERENCES storage.s3_multipart_uploads(id) ON DELETE CASCADE;


--
-- Name: vector_indexes vector_indexes_bucket_id_fkey; Type: FK CONSTRAINT; Schema: storage; Owner: -
--

ALTER TABLE ONLY storage.vector_indexes
    ADD CONSTRAINT vector_indexes_bucket_id_fkey FOREIGN KEY (bucket_id) REFERENCES storage.buckets_vectors(id);


--
-- Name: audit_log_entries; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.audit_log_entries ENABLE ROW LEVEL SECURITY;

--
-- Name: flow_state; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.flow_state ENABLE ROW LEVEL SECURITY;

--
-- Name: identities; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.identities ENABLE ROW LEVEL SECURITY;

--
-- Name: instances; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.instances ENABLE ROW LEVEL SECURITY;

--
-- Name: mfa_amr_claims; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.mfa_amr_claims ENABLE ROW LEVEL SECURITY;

--
-- Name: mfa_challenges; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.mfa_challenges ENABLE ROW LEVEL SECURITY;

--
-- Name: mfa_factors; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.mfa_factors ENABLE ROW LEVEL SECURITY;

--
-- Name: one_time_tokens; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.one_time_tokens ENABLE ROW LEVEL SECURITY;

--
-- Name: refresh_tokens; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.refresh_tokens ENABLE ROW LEVEL SECURITY;

--
-- Name: saml_providers; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.saml_providers ENABLE ROW LEVEL SECURITY;

--
-- Name: saml_relay_states; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.saml_relay_states ENABLE ROW LEVEL SECURITY;

--
-- Name: schema_migrations; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.schema_migrations ENABLE ROW LEVEL SECURITY;

--
-- Name: sessions; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.sessions ENABLE ROW LEVEL SECURITY;

--
-- Name: sso_domains; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.sso_domains ENABLE ROW LEVEL SECURITY;

--
-- Name: sso_providers; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.sso_providers ENABLE ROW LEVEL SECURITY;

--
-- Name: users; Type: ROW SECURITY; Schema: auth; Owner: -
--

ALTER TABLE auth.users ENABLE ROW LEVEL SECURITY;

--
-- Name: app_users Authenticated users can delete app users; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Authenticated users can delete app users" ON public.app_users FOR DELETE TO authenticated USING ((auth.role() = 'authenticated'::text));


--
-- Name: campaign_recipients Authenticated users can delete campaign recipients; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Authenticated users can delete campaign recipients" ON public.campaign_recipients FOR DELETE TO authenticated USING ((auth.role() = 'authenticated'::text));


--
-- Name: campaign_templates Authenticated users can delete campaign templates; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Authenticated users can delete campaign templates" ON public.campaign_templates FOR DELETE TO authenticated USING ((auth.role() = 'authenticated'::text));


--
-- Name: campaigns Authenticated users can delete campaigns; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Authenticated users can delete campaigns" ON public.campaigns FOR DELETE TO authenticated USING ((auth.role() = 'authenticated'::text));


--
-- Name: variants Authenticated users can delete variants; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Authenticated users can delete variants" ON public.variants FOR DELETE TO authenticated USING ((auth.role() = 'authenticated'::text));


--
-- Name: app_users Authenticated users can insert app users; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Authenticated users can insert app users" ON public.app_users FOR INSERT TO authenticated WITH CHECK ((auth.role() = 'authenticated'::text));


--
-- Name: campaign_recipients Authenticated users can insert campaign recipients; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Authenticated users can insert campaign recipients" ON public.campaign_recipients FOR INSERT TO authenticated WITH CHECK ((auth.role() = 'authenticated'::text));


--
-- Name: campaign_templates Authenticated users can insert campaign templates; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Authenticated users can insert campaign templates" ON public.campaign_templates FOR INSERT TO authenticated WITH CHECK ((auth.role() = 'authenticated'::text));


--
-- Name: campaigns Authenticated users can insert campaigns; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Authenticated users can insert campaigns" ON public.campaigns FOR INSERT TO authenticated WITH CHECK ((auth.role() = 'authenticated'::text));


--
-- Name: conversations Authenticated users can insert conversations; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Authenticated users can insert conversations" ON public.conversations FOR INSERT TO authenticated WITH CHECK ((auth.role() = 'authenticated'::text));


--
-- Name: leads Authenticated users can insert leads; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Authenticated users can insert leads" ON public.leads FOR INSERT TO authenticated WITH CHECK ((auth.role() = 'authenticated'::text));


--
-- Name: messages Authenticated users can insert messages; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Authenticated users can insert messages" ON public.messages FOR INSERT TO authenticated WITH CHECK ((auth.role() = 'authenticated'::text));


--
-- Name: variants Authenticated users can insert variants; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Authenticated users can insert variants" ON public.variants FOR INSERT TO authenticated WITH CHECK ((auth.role() = 'authenticated'::text));


--
-- Name: app_users Authenticated users can read app users; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Authenticated users can read app users" ON public.app_users FOR SELECT TO authenticated USING ((auth.role() = 'authenticated'::text));


--
-- Name: campaign_recipients Authenticated users can read campaign recipients; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Authenticated users can read campaign recipients" ON public.campaign_recipients FOR SELECT TO authenticated USING ((auth.role() = 'authenticated'::text));


--
-- Name: campaign_templates Authenticated users can read campaign templates; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Authenticated users can read campaign templates" ON public.campaign_templates FOR SELECT TO authenticated USING ((auth.role() = 'authenticated'::text));


--
-- Name: campaigns Authenticated users can read campaigns; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Authenticated users can read campaigns" ON public.campaigns FOR SELECT TO authenticated USING ((auth.role() = 'authenticated'::text));


--
-- Name: conversations Authenticated users can read conversations; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Authenticated users can read conversations" ON public.conversations FOR SELECT TO authenticated USING ((auth.role() = 'authenticated'::text));


--
-- Name: leads Authenticated users can read leads; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Authenticated users can read leads" ON public.leads FOR SELECT TO authenticated USING ((auth.role() = 'authenticated'::text));


--
-- Name: messages Authenticated users can read messages; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Authenticated users can read messages" ON public.messages FOR SELECT TO authenticated USING ((auth.role() = 'authenticated'::text));


--
-- Name: variants Authenticated users can read variants; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Authenticated users can read variants" ON public.variants FOR SELECT TO authenticated USING ((auth.role() = 'authenticated'::text));


--
-- Name: app_users Authenticated users can update app users; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Authenticated users can update app users" ON public.app_users FOR UPDATE TO authenticated USING ((auth.role() = 'authenticated'::text)) WITH CHECK ((auth.role() = 'authenticated'::text));


--
-- Name: campaign_recipients Authenticated users can update campaign recipients; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Authenticated users can update campaign recipients" ON public.campaign_recipients FOR UPDATE TO authenticated USING ((auth.role() = 'authenticated'::text)) WITH CHECK ((auth.role() = 'authenticated'::text));


--
-- Name: campaign_templates Authenticated users can update campaign templates; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Authenticated users can update campaign templates" ON public.campaign_templates FOR UPDATE TO authenticated USING ((auth.role() = 'authenticated'::text)) WITH CHECK ((auth.role() = 'authenticated'::text));


--
-- Name: campaigns Authenticated users can update campaigns; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Authenticated users can update campaigns" ON public.campaigns FOR UPDATE TO authenticated USING ((auth.role() = 'authenticated'::text)) WITH CHECK ((auth.role() = 'authenticated'::text));


--
-- Name: conversations Authenticated users can update conversations; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Authenticated users can update conversations" ON public.conversations FOR UPDATE TO authenticated USING ((auth.role() = 'authenticated'::text)) WITH CHECK ((auth.role() = 'authenticated'::text));


--
-- Name: leads Authenticated users can update leads; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Authenticated users can update leads" ON public.leads FOR UPDATE TO authenticated USING ((auth.role() = 'authenticated'::text)) WITH CHECK ((auth.role() = 'authenticated'::text));


--
-- Name: messages Authenticated users can update messages; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Authenticated users can update messages" ON public.messages FOR UPDATE TO authenticated USING ((auth.role() = 'authenticated'::text)) WITH CHECK ((auth.role() = 'authenticated'::text));


--
-- Name: variants Authenticated users can update variants; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Authenticated users can update variants" ON public.variants FOR UPDATE TO authenticated USING ((auth.role() = 'authenticated'::text)) WITH CHECK ((auth.role() = 'authenticated'::text));


--
-- Name: app_users; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.app_users ENABLE ROW LEVEL SECURITY;

--
-- Name: campaign_recipients; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.campaign_recipients ENABLE ROW LEVEL SECURITY;

--
-- Name: campaign_templates; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.campaign_templates ENABLE ROW LEVEL SECURITY;

--
-- Name: campaigns; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.campaigns ENABLE ROW LEVEL SECURITY;

--
-- Name: conversations; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;

--
-- Name: leads; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.leads ENABLE ROW LEVEL SECURITY;

--
-- Name: messages; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

--
-- Name: variants; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.variants ENABLE ROW LEVEL SECURITY;

--
-- Name: messages; Type: ROW SECURITY; Schema: realtime; Owner: -
--

ALTER TABLE realtime.messages ENABLE ROW LEVEL SECURITY;

--
-- Name: buckets; Type: ROW SECURITY; Schema: storage; Owner: -
--

ALTER TABLE storage.buckets ENABLE ROW LEVEL SECURITY;

--
-- Name: buckets_analytics; Type: ROW SECURITY; Schema: storage; Owner: -
--

ALTER TABLE storage.buckets_analytics ENABLE ROW LEVEL SECURITY;

--
-- Name: buckets_vectors; Type: ROW SECURITY; Schema: storage; Owner: -
--

ALTER TABLE storage.buckets_vectors ENABLE ROW LEVEL SECURITY;

--
-- Name: migrations; Type: ROW SECURITY; Schema: storage; Owner: -
--

ALTER TABLE storage.migrations ENABLE ROW LEVEL SECURITY;

--
-- Name: objects; Type: ROW SECURITY; Schema: storage; Owner: -
--

ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

--
-- Name: s3_multipart_uploads; Type: ROW SECURITY; Schema: storage; Owner: -
--

ALTER TABLE storage.s3_multipart_uploads ENABLE ROW LEVEL SECURITY;

--
-- Name: s3_multipart_uploads_parts; Type: ROW SECURITY; Schema: storage; Owner: -
--

ALTER TABLE storage.s3_multipart_uploads_parts ENABLE ROW LEVEL SECURITY;

--
-- Name: vector_indexes; Type: ROW SECURITY; Schema: storage; Owner: -
--

ALTER TABLE storage.vector_indexes ENABLE ROW LEVEL SECURITY;

--
-- Name: supabase_realtime; Type: PUBLICATION; Schema: -; Owner: -
--

CREATE PUBLICATION supabase_realtime WITH (publish = 'insert, update, delete, truncate');


--
-- Name: issue_graphql_placeholder; Type: EVENT TRIGGER; Schema: -; Owner: -
--

CREATE EVENT TRIGGER issue_graphql_placeholder ON sql_drop
         WHEN TAG IN ('DROP EXTENSION')
   EXECUTE FUNCTION extensions.set_graphql_placeholder();


--
-- Name: issue_pg_cron_access; Type: EVENT TRIGGER; Schema: -; Owner: -
--

CREATE EVENT TRIGGER issue_pg_cron_access ON ddl_command_end
         WHEN TAG IN ('CREATE EXTENSION')
   EXECUTE FUNCTION extensions.grant_pg_cron_access();


--
-- Name: issue_pg_graphql_access; Type: EVENT TRIGGER; Schema: -; Owner: -
--

CREATE EVENT TRIGGER issue_pg_graphql_access ON ddl_command_end
         WHEN TAG IN ('CREATE FUNCTION')
   EXECUTE FUNCTION extensions.grant_pg_graphql_access();


--
-- Name: issue_pg_net_access; Type: EVENT TRIGGER; Schema: -; Owner: -
--

CREATE EVENT TRIGGER issue_pg_net_access ON ddl_command_end
         WHEN TAG IN ('CREATE EXTENSION')
   EXECUTE FUNCTION extensions.grant_pg_net_access();


--
-- Name: pgrst_ddl_watch; Type: EVENT TRIGGER; Schema: -; Owner: -
--

CREATE EVENT TRIGGER pgrst_ddl_watch ON ddl_command_end
   EXECUTE FUNCTION extensions.pgrst_ddl_watch();


--
-- Name: pgrst_drop_watch; Type: EVENT TRIGGER; Schema: -; Owner: -
--

CREATE EVENT TRIGGER pgrst_drop_watch ON sql_drop
   EXECUTE FUNCTION extensions.pgrst_drop_watch();


--
-- PostgreSQL database dump complete
--

\unrestrict 2bU3O4z3oH5H796joTUJF74MT3udNY0XLrUXW5cOseoGFb1ztcZgkyF0Y5oc9H7

