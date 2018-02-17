# .bash_profile

# Get the aliases and functions
if [ -f ~/.bashrc ]; then
        . ~/.bashrc
fi

# User specific environment and startup programs

PATH=$PATH:$HOME/bin

export PATH

TMP=/tmp; export TMP
TMPDIR=$TMP; export TMPDIR
export ORACLE_BASE=/u01/app/oracle;
export ORACLE_HOME=/u01/app/oracle/product/12.1.0/dbhome_1;
ORACLE_SID=testdb; export ORACLE_SID
PATH=/usr/sbin:$PATH;export PATH
PATH=$ORACLE_HOME/bin:$PATH; export PATH
LD_LIBRARY_PATH=$ORACLE_HOME/lib:/lib:/usr/lib; export LD_LIBRARY_PATH
CLASSPATH=$ORACLE_HOME/jlib:$ORACLE_HOME/rdbms/jlib; export CLASSPATH
if [ $USER = "oracle" ]; then
if [ $SHELL = "/bin/ksh" ]; then
ulimit -p 16384
ulimit -n 65536
else
ulimit -u 16384 -n 65536
fi
fi
