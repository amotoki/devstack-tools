sa_echo = False
sql_connection = 'mysql://root:stackdb@localhost/testdb?charset=utf8'

import sqlalchemy
from sqlalchemy import create_engine

print sqlalchemy.__version__
engine = create_engine(sql_connection, echo=sa_echo)

#------------------------------------------------------------

from sqlalchemy import Table, Column, Integer, String, MetaData, ForeignKey

#metadata = MetaData()
#users_table = Table('users', metadata,
#                    Column('id', Integer, primary_key=True),
#                    Column('name', String(255)),
#                    Column('fullname', String(255)),
#                    Column('password', String(255))
#                    )
#metadata.create_all(engine)
#
#class User(object):
#    def __init__(self, name, fullname, password):
#        self.name = name
#        self.fullname = fullname
#        self.password = password
#
#    def __repr__(self):
#        return "<User('%s','%s', '%s')>" % (self.name, self.fullname,
#                                            self.password)
#
#from sqlalchemy.orm import mapper
#mapper(User, users_table)

from sqlalchemy.ext.declarative import declarative_base
Base = declarative_base()
class User(Base):
    __tablename__ = 'users'

    id = Column(Integer, primary_key=True)
    name = Column(String(255))
    fullname = Column(String(255))
    password = Column(String(255))

    def __init__(self, name, fullname, password):
        self.name = name
        self.fullname = fullname
        self.password = password

    def __repr__(self):
        return "<User('%s','%s', '%s')>" % (self.name, self.fullname,
                                            self.password)

#------------------------------------------------------------

from sqlalchemy.orm import sessionmaker
#Session = sessionmaker(bind=engine)
Session = sessionmaker(bind=engine, autocommit=True, expire_on_commit=False)
session = Session()
