import sqlalchemy as sa
from sqlalchemy.orm import sessionmaker

ECHO = False
CONNECTION = 'mysql://root:stackdb@127.0.0.1/neutron_nec?charset=utf8'

ENGINE = None
SESSION_MAKER = None

print sa.__version__

def create_engine(connection=None, echo=False, recreate=False):
    global ENGINE
    global SESSION_MAKER
    if not connection:
        connection = CONNECTION
    if recreate:
        ENGINE = None
        SESSION_MAKER = None
    if not ENGINE:
        ENGINE = sa.create_engine(connection, echo=echo)
    return ENGINE

def get_session(connection=None, echo=False,
                autocommit=True, expire_on_commit=False):
    global SESSION_MAKER
    engine = create_engine()
    if not SESSION_MAKER:
        SESSION_MAKER = sessionmaker(bind=engine,
                                     autocommit=autocommit,
                                     expire_on_commit=expire_on_commit)
    return SESSION_MAKER()


from neutron.db import models_v2 as core
from neutron.plugins.nec.db import models as nmodels

session = get_session()
