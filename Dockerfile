FROM debian:bullseye

RUN apt-get update \
 && apt-get install -y locales \
 && dpkg-reconfigure -f noninteractive locales \
 && locale-gen C.UTF-8 \
 && /usr/sbin/update-locale LANG=C.UTF-8 \
 && echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
 && locale-gen \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# Users with other locales should set this in their derivative image
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

RUN apt-get update \
 && apt-get install -y curl unzip procps \
    python3 python3-setuptools r-base \
 && ln -s /usr/bin/python3 /usr/bin/python \
# && easy_install3 pip py4j \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# http://blog.stuart.axelbrooke.com/python-3-on-spark-return-of-the-pythonhashseed
ENV PYTHONHASHSEED 0
ENV PYTHONIOENCODING UTF-8
ENV PIP_DISABLE_PIP_VERSION_CHECK 1

# JAVA
RUN apt-get update \
 && apt-get install -y openjdk-11-jre \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# SPARK
ENV SPARK_VERSION 2.3.1
ENV HADOOP_VERSION 2.7
ENV SPARK_PACKAGE spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}
ENV SPARK_HOME /usr/spark-${SPARK_VERSION}
ENV SPARK_DIST_CLASSPATH="$HADOOP_HOME/etc/hadoop/*:$HADOOP_HOME/share/hadoop/common/lib/*:$HADOOP_HOME/share/hadoop/common/*:$HADOOP_HOME/share/hadoop/hdfs/*:$HADOOP_HOME/share/hadoop/hdfs/lib/*:$HADOOP_HOME/share/hadoop/hdfs/*:$HADOOP_HOME/share/hadoop/yarn/lib/*:$HADOOP_HOME/share/hadoop/yarn/*:$HADOOP_HOME/share/hadoop/mapreduce/lib/*:$HADOOP_HOME/share/hadoop/mapreduce/*:$HADOOP_HOME/share/hadoop/tools/lib/*"
ENV PATH $PATH:${SPARK_HOME}/bin
RUN curl -sL --retry 3 \
  "https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/${SPARK_PACKAGE}.tgz" \
  | gunzip \
  | tar x -C /usr/ \
 && mv /usr/$SPARK_PACKAGE $SPARK_HOME \
 && chown -R root:root $SPARK_HOME

#MYSQL jar
RUN curl -sL --retry 3 \
  "https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-5.1.47.tar.gz" \
  | gunzip \
  | tar x -C /usr/ \
 && mv /usr/mysql-connector-java-5.1.47/mysql-connector-java-5.1.47.jar $SPARK_HOME/jars/mysql-connector-java-5.1.47.jar

# LIVY
ENV LIVY_VERSION 0.6.0-incubating
ENV LIVY_HOME /usr/apache-livy-${LIVY_VERSION}-bin
RUN curl -sL --retry 3 \
  "http://apache.mirror.globo.tech/incubator/livy/0.6.0-incubating/apache-livy-${LIVY_VERSION}-bin.zip" --output apache-livy-${LIVY_VERSION}-bin.zip
RUN unzip apache-livy-${LIVY_VERSION}-bin.zip
RUN mv apache-livy-${LIVY_VERSION}-bin /usr/apache-livy-${LIVY_VERSION}-bin
#RUN mv /usr/apache-livy-${LIVY_VERSION}-bin/conf/livy.conf.template /usr/apache-livy-${LIVY_VERSION}-bin/conf/livy.conf
#ENV firstStr ".*livy\.spark\.master = local"
#ENV secondStr "livy\.spark\.master = spark:\/\/master:7077" 
#RUN sed -i "s/${firstStr}/${secondStr}/g" /usr/apache-livy-${LIVY_VERSION}-bin/conf/livy.conf
#ENV firstStr ".*livy\.server\.port = 8998"
#ENV secondStr "livy\.server\.port = 8090"
#RUN sed -i "s/${firstStr}/${secondStr}/g" /usr/apache-livy-${LIVY_VERSION}-bin/conf/livy.conf

WORKDIR $SPARK_HOME
CMD ["bin/spark-class", "org.apache.spark.deploy.master.Master"]
