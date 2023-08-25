### 明确指标体系

明确统计指标具体的工作是，深入分析需求，构建指标体系。构建指标体系的主要意义就是指标定义标准化。所有指标的定义，都必须遵循同一套标准，这样能有效的避免指标定义存在歧义，指标定义重复等问题。

**1）指标体系相关概念**

（1）原子指标

原子指标基于某一业务过程的度量值，是业务定义中不可再拆解的指标，原子指标的核心功能就是对指标的聚合逻辑进行了定义。我们可以得出结论，原子指标包含三要素，分别是业务过程、度量值和聚合逻辑。

例如订单总额就是一个典型的原子指标，其中的业务过程为用户下单、度量值为订单金额，聚合逻辑为sum()求和。需要注意的是原子指标只是用来辅助定义指标一个概念，通常不会对应有实际统计需求与之对应。

（2）派生指标

派生指标基于原子指标，其与原子指标的关系如下

派生指标 = 原子指标 + 统计周期 + 业务限定 + 统计粒度

例如： 最近一天各个省份下单总额 = 下单总额 + 最近一天 + 无 + 省份

（3）衍生指标

衍生指标是在一个或多个派生指标的基础上，通过各种逻辑运算复合而成的。例如比率、比例等类型的指标。衍生指标也会对应实际的统计需求

**2）指标体系对于数仓建模的意义**

通过上述两个具体的案例可以看出，绝大多数的统计需求，都可以使用原子指标、派生指标以及衍生指标这套标准去定义。同时能够发现这些统计需求都直接的或间接的对应一个或者是多个派生指标。

当统计需求足够多时，必然会出现部分统计需求对应的派生指标相同的情况。这种情况下，我们就可以考虑将这些公共的派生指标保存下来，这样做的主要目的就是减少重复计算，提高数据的复用性。

这些公共的派生指标统一保存在数据仓库的DWS层。因此DWS层设计，就可以参考我们根据现有的统计需求整理出的派生指标。

#### 建表

1、交易域机构货物类型粒度下单 1 日汇总表

```sql
drop table if exists dws_trade_org_cargo_type_order_1d;
create external table dws_trade_org_cargo_type_order_1d
(
    `org_id`          bigint comment '机构ID',
    `org_name`        string comment '转运站名称',
    `city_id`         bigint comment '城市ID',
    `city_name`       string comment '城市名称',
    `cargo_type`      string comment '货物类型',
    `cargo_type_name` string comment '货物类型名称',
    `order_count`     bigint comment '下单数',
    `order_amount`    decimal(16, 2) comment '下单金额'
) comment '交易域机构货物类型粒度下单 1 日汇总表'
    partitioned by (`dt` string comment '统计日期')
    stored as orc
    location '/warehouse/tms/dws/dws_trade_org_cargo_type_order_1d'
    tblproperties ('orc.compress' = 'snappy');


set hive.exec.dynamic.partition.mode=nonstrict;
---首日数据加载，需要处理历史数据，将上线前的日期放到不同的partition中
with od as (select sender_district_id,
                   sender_complex_id,
                   cargo_type,
                   cargo_type_name,
                   amount,
                   dt
            from dwd_trade_order_detail_inc
            where dt <= '2023-01-10'),
     og as (select id,
                   org_name,
                   region_id
            from dim_organ_full
            where dt = '2023-01-10'),
     cx as (select id,
                   city_id,
                   city_name
            from dim_complex_full
            where dt = '2023-01-10')
insert overwrite table dws_trade_org_cargo_type_order_1d partition (dt)
select og.id,
       og.org_name,
       city_id,
       city_name,
       cargo_type,
       cargo_type_name,
       count(1) order_count,
       sum(amount) order_amount,
       dt
from od
         left join og on od.sender_district_id = og.region_id
         left join cx on od.sender_complex_id = cx.id
group by og.id, og.org_name, city_id, city_name, cargo_type, cargo_type_name, dt;

----每日数据加载

with od as (select sender_district_id,
                   sender_complex_id,
                   cargo_type,
                   cargo_type_name,
                   amount,
                   dt
            from dwd_trade_order_detail_inc
            where dt = '2023-01-11'),
     og as (select id,
                   org_name,
                   region_id
            from dim_organ_full
            where dt = '2023-01-11'),
     cx as (select id,
                   city_id,
                   city_name
            from dim_complex_full
            where dt = '2023-01-11')
insert overwrite table dws_trade_org_cargo_type_order_1d partition (dt='2023-01-11')
select og.id,
       og.org_name,
       city_id,
       city_name,
       cargo_type,
       cargo_type_name,
       count(1) order_count,
       sum(amount) order_amount
from od
         left join og on od.sender_district_id = og.region_id
         left join cx on od.sender_complex_id = cx.id
group by og.id, og.org_name, city_id, city_name, cargo_type, cargo_type_name, dt;


```

