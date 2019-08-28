---
title: Banner图模块错题本
date: 2019-08-28 11:18:06
categories: ["2019-08"]
tags: ["错题本"]
---
……尝试治一下自己的毛病

大致就是，写代码的时候做出许多假设，测试的时候发现假设并不总是成立。。

很多都是非常细小的问题，交付一个模块的时候记一下，不要再犯就是了

1 关联查询时，由于习惯Mybatis Plus的自动过滤逻辑删除特性，自己撰写SQL时没有过滤关联查询表的已经逻辑删除的记录、以及子表中不存在的记录
代码：

```java
@Select("select m.id as module_id,m.is_required,m.title,m.subtitle,m.type,i.file_id,i.product_id,i.pno " +
            "from wsc_pc_banner_module m left join wsc_pc_banner_image i on i.module_id = m.id " +
            "${ew.customSqlSegment} and (i.is_deleted is NULL or i.is_deleted = 0) and m.is_deleted = 0 order by m.id")
    List<WscPcBannerDO> selectBanner(@Param(Constants.WRAPPER) Wrapper wrapper);
```
重点在于`and (i.is_deleted is NULL or i.is_deleted = 0)`

2 根据类型筛选Banner图，前端应该这么传值：

```http
GET {{adminHost}}/microManage/pcBanner?type=0&type=3&type=4&type=5
Content-Type: application/json
Authorization: {{adminToken}}
```
后端应该这么接受：
```java
@GetMapping("/pcBanner")
public JsonResult pcBanner(@RequestParam(required = false) Integer[] type) {
    //...
}
```
前端直接用[0,3,4,5]这样的后端是接收不到的。。后端也不能用List<Integer>来接受。。感觉这个设计有一点丑，但又不想额外写代码转换。。

剩下的是一些业务上的问题，没记清楚需求之类的。。这模块应该就这些问题