#! /bin/bash
#
# entrypoint.sh
# Copyleft (ɔ) 2016 Thiago Almeida <thiagoalmeidasa@gmail.com>
#
# Distributed under terms of the GPLv2 license.
#

set -e

[[ -n $DEBUG_ENTRYPOINT ]] && set -x

EP_TITLE=${EP_TITLE:-Etherpad}
EP_PORT=${EP_PORT:-9001}
DB_TYPE=${DB_TYPE:-}
DB_HOST=${DB_HOST:-}
DB_PORT=${DB_PORT:-}
DB_NAME=${DB_NAME:-}
DB_USER=${DB_USER:-}
DB_PASS=${DB_PASS:-}


ADMIN_PASS=${ADMIN_PASS:-admin}
FAVICON_URL=${FAVICON_URL:-favicon.ico}
ABIWORD=${ABIWORD:-false}
ABIWORD_PATH=${ABIWORD_PATH:-null}
PLUGINS=${PLUGINS:-false}
if [ "${ABIWORD}" == 'false'  ]; then
    ABIWORD_PATH=null
else
    ABIWORD_PATH='"/usr/bin/abiword"'
fi
SETTINGS_FILE=/data/settings.json

#



# Check if the settings have to be created
if [ ! -f $SETTINGS_FILE ]
then
    echo "Generating settings file ${SETTINGS_FILE}"

	# GENERATE SETTINGS
	
	# is a mysql or postgresql database linked?
	# requires that the mysql or postgresql containers have exposed
	# port 3306 and 5432 respectively.
	if [[ -n ${MYSQL_PORT_3306_TCP_ADDR} ]]; then
	  DB_TYPE=${DB_TYPE:-mysql}
	  DB_HOST=${DB_HOST:-${MYSQL_PORT_3306_TCP_ADDR}}
	  DB_PORT=${DB_PORT:-${MYSQL_PORT_3306_TCP_PORT}}
	
	  # support for linked sameersbn/mysql image
	  DB_USER=${DB_USER:-${MYSQL_ENV_DB_USER}}
	  DB_PASS=${DB_PASS:-${MYSQL_ENV_DB_PASS}}
	  DB_NAME=${DB_NAME:-${MYSQL_ENV_DB_NAME}}
	
	  # support for linked orchardup/mysql and enturylink/mysql image
	  # also supports official mysql image
	  DB_USER=${DB_USER:-${MYSQL_ENV_MYSQL_USER}}
	  DB_PASS=${DB_PASS:-${MYSQL_ENV_MYSQL_PASSWORD}}
	  DB_NAME=${DB_NAME:-${MYSQL_ENV_MYSQL_DATABASE}}
	elif [[ -n ${POSTGRESQL_PORT_5432_TCP_ADDR} ]]; then
	  DB_TYPE=${DB_TYPE:-postgres}
	  DB_HOST=${DB_HOST:-${POSTGRESQL_PORT_5432_TCP_ADDR}}
	  DB_PORT=${DB_PORT:-${POSTGRESQL_PORT_5432_TCP_PORT}}
	
	  # support for linked official postgres image
	  DB_USER=${DB_USER:-${POSTGRESQL_ENV_POSTGRES_USER}}
	  DB_PASS=${DB_PASS:-${POSTGRESQL_ENV_POSTGRES_PASSWORD}}
	  DB_NAME=${DB_NAME:-${DB_USER}}
	
	  # support for linked sameersbn/postgresql image
	  DB_USER=${DB_USER:-${POSTGRESQL_ENV_DB_USER}}
	  DB_PASS=${DB_PASS:-${POSTGRESQL_ENV_DB_PASS}}
	  DB_NAME=${DB_NAME:-${POSTGRESQL_ENV_DB_NAME}}
	
	  # support for linked orchardup/postgresql image
	  DB_USER=${DB_USER:-${POSTGRESQL_ENV_POSTGRESQL_USER}}
	  DB_PASS=${DB_PASS:-${POSTGRESQL_ENV_POSTGRESQL_PASS}}
	  DB_NAME=${DB_NAME:-${POSTGRESQL_ENV_POSTGRESQL_DB}}
	
	  # support for linked paintedfox/postgresql image
	  DB_USER=${DB_USER:-${POSTGRESQL_ENV_USER}}
	  DB_PASS=${DB_PASS:-${POSTGRESQL_ENV_PASS}}
	  DB_NAME=${DB_NAME:-${POSTGRESQL_ENV_DB}}
	fi
	
	if [[ -z ${DB_HOST} ]]; then
	  echo "ERROR: "
	  echo "  Please configure the database connection."
	  echo "  Refer http://git.io/wkYhyA for more information."
	  echo "  Cannot continue without a database. Aborting..."
	  exit 1
	fi
	
	# use default port number if it is still not set
	case ${DB_TYPE} in
	  mysql) DB_PORT=${DB_PORT:-3306} ;;
	  postgres) DB_PORT=${DB_PORT:-5432} ;;
	  *)
	    echo "ERROR: "
	    echo "  Please specify the database type in use via the DB_TYPE configuration option."
	    echo "  Accepted values are \"postgres\" or \"mysql\". Aborting..."
	    exit 1
	    ;;
	esac
	
	
	cat > ${SETTINGS_FILE} <<END_OF_TEMPLATE
	/*
	  This file must be valid JSON. But comments are allowed
	
	  Please edit settings.json, not settings.json.template
	*/
	{
	  // Name your instance!
	  "title": "${EP_TITLE}",
	
	  // favicon default name
	  // alternatively, set up a fully specified Url to your own favicon
	  "favicon": "${FAVICON_URL}",
	
	  //IP and port which etherpad should bind at
	  "ip": "0.0.0.0",
	  "port" : "${EP_PORT}",
	
	
	  /*
	  // Node native SSL support
	  // this is disabled by default
	  //
	  // make sure to have the minimum and correct file access permissions set
	  // so that the Etherpad server can access them
	
	  // "ssl" : {
	  //           "key"  : "/path-to-your/epl-server.key",
	  //           "cert" : "/path-to-your/epl-server.crt"
	  //         },
	
	  */
	
	  //The Type of the database. You can choose between dirty, postgres, sqlite and mysql
	  //You shouldn't use "dirty" for for anything else than testing or development
	
	  "dbType" : "${DB_TYPE}",
	   "dbSettings" : {
	                    "user"    : "${DB_USER}",
	                    "host"    : "${DB_HOST}",
	                    "password": "${DB_PASS}",
	                    "database": "${DB_NAME}"
	                  },
	
	  //the default text of a pad
	  "defaultPadText" : "",
	
	  /* Users must have a session to access pads. This effectively allows only group pads to be accessed. */
	  "requireSession" : false,
	
	  /* Users may edit pads but not create new ones. Pad creation is only via the API. This applies both to group pads and regular pads. */
	  "editOnly" : false,
	
	  /* if true, all css & js will be minified before sending to the client. This will improve the loading performance massivly,
	     but makes it impossible to debug the javascript/css */
	  "minify" : true,
	
	  /* How long may clients use served javascript code (in seconds)? Without versioning this
	     may cause problems during deployment. Set to 0 to disable caching */
	  "maxAge" : 21600, // 60 * 60 * 6 = 6 hours
	
	  /* This is the path to the Abiword executable. Setting it to null, disables abiword.
	     Abiword is needed to advanced import/export features of pads*/
	  "abiword" : $ABIWORD_PATH,
	
	  /* This setting is used if you require authentication of all users.
	     Note: /admin always requires authentication. */
	  "requireAuthentication": false,
	
	  /* Require authorization by a module, or a user with is_admin set, see below. */
	  "requireAuthorization": false,
	
	  /*when you use NginX or another proxy/ load-balancer set this to true*/
	  "trustProxy": true,
	
	  /* Privacy: disable IP logging */
	  "disableIPlogging": false,
	
	  /* Users for basic authentication. is_admin = true gives access to /admin.
	     If you do not uncomment this, /admin will not be available! */
	  "users": {
	    "admin": {
	      "password": "${ADMIN_PASS}",
	      "is_admin": true
	    }
	  },
	
	  // restrict socket.io transport methods
	  "socketTransportProtocols" : ["xhr-polling", "jsonp-polling", "htmlfile"],
	
	  /* The toolbar buttons configuration.
	  "toolbar": {
	    "left": [
	      ["bold", "italic", "underline", "strikethrough"],
	      ["orderedlist", "unorderedlist", "indent", "outdent"],
	      ["undo", "redo"],
	      ["clearauthorship"]
	    ],
	    "right": [
	      ["importexport", "timeslider", "savedrevision"],
	      ["settings", "embed"],
	      ["showusers"]
	    ],
	    "timeslider": [
	      ["timeslider_export", "timeslider_returnToPad"]
	    ]
	  },
	  */
	
	  /* The log level we are using, can be: DEBUG, INFO, WARN, ERROR */
	  "loglevel": "INFO",
	
	  //Logging configuration. See log4js documentation for further information
	  // https://github.com/nomiddlename/log4js-node
	  // You can add as many appenders as you want here:
	  "logconfig" :
	    { "appenders": [
	        { "type": "console"
	        //, "category": "access"// only logs pad access
	        }
	      , { "type": "file"
	      , "filename": "/data/etherpad.log"
	      , "maxLogSize": 1024
	      , "backups": 3 // how many log files there're gonna be at max
	      //, "category": "test" // only log a specific category
	        }
	    /*
	      , { "type": "logLevelFilter"
	        , "level": "warn" // filters out all log messages that have a lower level than "error"
	        , "appender":
	          {  Use whatever appender you want here  }
	        }*/
	    /*
	      , { "type": "logLevelFilter"
	        , "level": "error" // filters out all log messages that have a lower level than "error"
	        , "appender":
	          { "type": "smtp"
	          , "subject": "An error occured in your EPL instance!"
	          , "recipients": "bar@blurdybloop.com, baz@blurdybloop.com"
	          , "sendInterval": 60*5 // in secs -- will buffer log messages; set to 0 to send a mail for every message
	          , "transport": "SMTP", "SMTP": { // see https://github.com/andris9/Nodemailer#possible-transport-methods
	              "host": "smtp.example.com", "port": 465,
	              "secureConnection": true,
	              "auth": {
	                  "user": "foo@example.com",
	                  "pass": "bar_foo"
	              }
	            }
	          }
	        }*/
	      ]
	    }
	}
END_OF_TEMPLATE

fi

# Solve problems with restart container database;
OLDIP=`awk -F '"' '/172.17/ {print $4}' ${SETTINGS_FILE}`

if [ ${OLDIP} != ${MYSQL_PORT_3306_TCP_ADDR} ]; then
    sed -i 's/'"$OLDIP"'/'"$MYSQL_PORT_3306_TCP_ADDR"'/g' ${SETTINGS_FILE}
fi

# Running with supervisor

cp $SETTINGS_FILE settings.json
supervisord -c /etc/supervisor/supervisor.conf -n
