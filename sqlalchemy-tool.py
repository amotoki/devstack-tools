import sqlalchemy as sa
from sqlalchemy.orm import sessionmaker

ECHO = True
DEFAULT_CONNECTION = 'mysql://root:stackdb@127.0.0.1/neutron_nec?charset=utf8'
CONNECTION_FORMAT = '%(backend)s://root:stackdb@127.0.0.1/%(database)s?charset=utf8'

ENGINE = None
SESSION_MAKER = None

print sa.__version__


def create_engine(connection=None, echo=False, recreate=False):
    global ENGINE
    global SESSION_MAKER
    if not connection:
        connection = DEFAULT_CONNECTION
    if recreate:
        ENGINE = None
        SESSION_MAKER = None
    if not ENGINE:
        ENGINE = sa.create_engine(connection, echo=echo)
        print 'Create engine (connection=%s, echo=%s)' % (connection, echo)
    return ENGINE


def get_session(connection=None, echo=False,
                autocommit=True, expire_on_commit=False,
                recreate=False):
    global SESSION_MAKER
    engine = create_engine(connection, echo, recreate)
    if not SESSION_MAKER:
        SESSION_MAKER = sessionmaker(bind=engine,
                                     autocommit=autocommit,
                                     expire_on_commit=expire_on_commit)
        print 'Create session'
    return SESSION_MAKER()


def get_session_wrapper(database=None, backend=None,
                        echo=False, autocommit=True, expire_on_commit=False,
                        recreate=True):
    database = database or 'neutron_nec'
    backend = backend or 'mysql'
    connection = CONNECTION_FORMAT % {'database': database, 'backend': backend}
    return get_session(connection, echo, autocommit, expire_on_commit, recreate)


from neutron.db import models_v2 as core
from neutron.plugins.nec.db import models as nmodels


session = get_session()
