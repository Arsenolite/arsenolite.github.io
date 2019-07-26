---
title: jOOQ比起MyBatis的便利之处
tags: ["Java","MyBatis","jOOQ"]
categories: ["2018-10"]
date: 2018-10-12 15:13:04
---
单位新项目用了新的持久化框架，叫[jOOQ](https://www.jooq.org/)。

用惯MyBatis的我一开始有些不适应，但是写过新项目之后，回去维护老项目，确实感觉基于XML的MyBatis编码效率低下。

首先，两边同样有自动生成代码的工具。
MyBatis生成的有Dao层和pojo，需要配置生成哪张表的pojo，（随口一提，公司的生成器配置可能有bug，生成XML时并不会清空之前的XML内容，需要手动清空/删除一次。）

生成的dao提供的方法有：
+ 根据主键获取
+ 插入
+ 可选插入（pojo对应字段不是null的时候才设值）
+ 更新
+ 可选更新（不是null的时候才更新值）
+ 逻辑删除

pojo则是数据库的各字段以及get/set方法，值得一提的是每个字段上会有DDL里的列备注，但是会充斥大量空行，阅读起来较为困难。

而jOOQ的代码生成器一次性生成所有表的dao层和pojo。dao层全部继承了一个叫DAOImpl的抽象类，提供了以下方法：
+ 新增单个pojo
+ 新增多个pojo（可变参数）
+ 新增多个pojo（集合）
+ 用以上三种方式更新、**物理删除**pojo
+ 根据主键判断是否存在 
+ 获取表中记录总数
+ 获取整张表
+ 利用Java8的Optional来获取（大概是允许参数为null？）
+ 获取主键

还有一些看不太懂的方法：
+ `private /* non-final */ Condition equal(Field<?>[] pk, Collection<T> ids)` 
+ `private /* non-final */ List<R> records(Collection<P> objects, boolean forUpdate)`
+ `private /* non-final */ RecordListenerProvider[] providers(final RecordListenerProvider[] providers, final Object object)`

而每个表不同的dao实现类也有各自的方法：
+ 根据主键（项目里就是id）获取
+ 根据多个id获取多个记录（可变参数）
+ 根据每个唯一索引获取记录
+ 根据每个列获取多条记录，也支持可变参数

比MyBatis丰富很多，唯一的缺陷是没有自动生成的逻辑删除方法，初次维护项目很容易根据直觉使用delete方法，需要自动生成Service层代码进行封装。

生成的pojo则兼容了JPA的注解（目前没有在项目里用上），这方面有点hibernate的画风？ 较MyBatis生成的pojo要紧凑很多，少了很多无谓的空行。
当业务变化，建立新表，jOOQ生成的代码可以快速满足大部分业务。


说完自动生成的代码，接下来谈谈编写业务代码的复杂度。
贴一段使用MyBatis的传统项目里的单表分页查询代码：

首先需要编写XML：
```xml
<?xml version="1.0" encoding="UTF-8" ?>
<!DOCTYPE mapper PUBLIC "-//mybatis.org//DTD Mapper 3.0//EN" "http://mybatis.org/dtd/mybatis-3-mapper.dtd" >
<mapper namespace="对应的dao接口类名">
    <select id="selectByPageQuery"
            resultMap="自动生成的Mapper里的ResultMap">
        select * from 表
        where is_deleted = 0
        order by id desc
        LIMIT #{itemIndex}, #{pageSize}
    </select>

    <select id="countByPageQuery" resultType="java.lang.Integer">
        select count(*) from 表
        where is_deleted = 0
        LIMIT #{itemIndex}, #{pageSize}
    </select>
</mapper>
```
由于多个Mapper需要公用`LIMIT #{itemIndex}, #{pageSize}` 这段语句（还有一些权限控制的语句），事实上代码是这样的：
```xml
<include refid="com.***.dao.mapper.fragment.PageMapper.pageLimit"/>
```
所以无法使用注解方式的SQL。
接下来是接口：
```java
public interface 表SimpleSelectDao {
    int countByPageQuery(PageQuery query);
    List<自动生成的实体类> selectByPageQuery(PageQuery query);
}
```
其中`PageQuery`是公司封装的分页类，不贴代码了，可以从SQL里看出用到的字段。
然后再在Service层使用：
```java
...
int count = parcelTransferRecordSimpleSelectDao.countByPageQuery(query);
query.setItemTotal(count);
List<TxParcelTransferRecord> records = parcelTransferRecordSimpleSelectDao.selectByPageQuery(query);
...
```

相对于基于XML的MyBatis，jOOQ在业务变动时编写代码的效率更高，同样是分页获取代码，只需要7行：

说明：
`Pageable`是Spring 5的分页相关类，专门解决从前端传参到数据库查询的分页问题，不需要自己实现分页框架了。
`Tuple2`是公司内部实现的数据结构，用来返回两个不同类型的数据。
`SelectConditionStep`和`dsl`是jOOQ提供的类和对象，其中dsl的类是`DSLContext`，用于执行SQL，改写生成器后可以使用Spring注入。

```java
public Tuple2<List<表实体类>, Integer> pageVoById(Pageable pageable) {
    SelectConditionStep<表Record类> step = dsl.selectFrom(表的枚举)
            .where(表的枚举.IS_DELETED.eq(false));
    List<表实体类> list = step.orderBy(表的枚举.ID.desc())
            .limit((int) pageable.getOffset(), pageable.getPageSize())
            .fetchInto(表实体类.class);
    int count = dsl.fetchCount(step);
    return new Tuple2<>(list, count);
}
```

这段代码出现在Service层，用惯之后很符合人类直觉，发挥了SQL人类可读性好的优势。

jOOQ封装了sql，将所有的字段和SQL语句化为Java代码，当然也可以传入完整或者部分的sql执行，自由度很高，同时有Java强类型的优势加持，屏蔽掉了MyBatis的`ResultMapper`环节，每一步SQL执行虽然要使用一些复杂的类和对象（例如`SelectConditionStep`），对习惯使用强类型语言的java码狗来说很有“安全感”。

相比jOOQ，基于XML的MyBatis代码编写繁琐，手写SQL经常漏掉`order by id desc`（页面上刚刚新增的记录在最前面）和`is_deleted = 0`（其实这是低级失误），查找SQL需要跳转两次（这还是装了IDE插件的情况），在多表查询时还要编写复杂的ResultMap，体验确实差很多。




