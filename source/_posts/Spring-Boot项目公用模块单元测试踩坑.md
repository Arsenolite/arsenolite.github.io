---
title: Spring Boot项目公用模块单元测试踩坑
date: 2019-05-15 11:31:15
categories: ["2019-05"]
tags: ["Java","单元测试"]
---
现在手头的项目分为几个子模块，前台一个，后台一个，计划任务一个，Service、bo、dao等放在common模块里，而common模块作为其他几个模块的依赖存在。

在加入Spring环境的单元测试时报了错：
```
java.lang.IllegalStateException: Unable to find a @SpringBootConfiguration, you need to use @ContextConfiguration or @SpringBootTest(classes=...) with your test
```

按提示在测试类加入`@SpringBootConfiguration`后，报错变了：
```
Parameter 0 of method setXXService in com.XXX.common.XXXServiceImplTest required a bean of type 'com.XXX.common.XXXService' that could not be found.
```

Google了一下，发现这种情况是Application启动类不存在导致的，可是既然是依赖，自然就没有Application启动类，于是我尝试加入`@SpringBootTest(classes="要测试的Service")`，然后发现该Service注入到测试类成功了，但是Service中的几个成员注入失败，报错是找不到Bean。

查了一下发现，单元测试执行时，Spring会扫描这个class指定的类所在的包的所有子包，也就是一定要有一个打了`@SpringBootApplication`注解的类存在于common包下！

先建一个Root.class应付了事，然后慢慢研究：

在测试类加入注解`@ComponentScan(basePackages = {"com.XXX.common"})`,这回报错又变了：

```
Parameter 0 of method setXXXMapper in com.XXX.common.service.impl.XXXServiceImpl required a bean of type 'com.XXX.common.domain.repository.XXXMapper' that could not be found.
```

项目中用了Mybatis-Plus，该Mapper接口继承了`BaseMapper<>`，加了@Mapper和@Repository注解，难道@Repository注解不认？？

暂且先改为@Component，报错变成了这样：

```
Parameter 0 of method setObjectMapper in com.XXX.common.service.impl.XXXServiceImpl required a bean of type 'com.fasterxml.jackson.databind.ObjectMapper' that could not be found.

```
原来是忘记把Jackson的ObjectMapper纳入Spring 管理了：

```java
    @Bean
    public ObjectMapper objectMapper() {
        return new ObjectMapper();
    }
```

接下来依然是Mapper接口报错找不到Bean……无奈先用Root.class顶过去，日后再说）

2019-8-28更新

最后的解决方案是不在Common模块里写测试用例……