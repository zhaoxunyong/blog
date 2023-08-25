### ODS层的设计要点如下：

（1）ODS层的表结构设计依托于从业务系统同步过来的数据结构。

（2）ODS层要保存全部历史数据，故其压缩格式应选择压缩比较高的，此处选择gzip。

（3）ODS层表名的命名规范为：ods\_表名\_单分区增量全量标识（inc/full）。建

##### 全量表

```sql
create external table ods_base_complex_full(
    id bigint,
    complex_name string,
    province_id bigint,
    city_id bigint,
    district_id bigint,
    district_name string,
    create_time string,
    update_time string,
    is_delete string
)partitioned by (dt string)
row format delimited fields terminated by  '\t' null defined as ''
stored as  textfile
location '/warehouse/tms/ods/ods_base_complex_full';

load data inpath '/origin_data/tms/base_complex_full/2023-01-10' overwrite into table ods_base_complex_full partition (dt='2023-01-10');
	
```

增量表

json建表

原始数据

```json
{"id":"1001","name":"lisi","dept":{"deptId":"A01","dept name":"开发部"},"xq":["打篮球","打游戏"]}
{"id":"1002","name":"wangwu","dept":{"deptId":"A02","dept name":"市场部"},"xq":["看书","上网"]}
{"id":"1003","name":"zhaoliu","dept":{"deptId":"A03","dept name":"公关部"},"xq":["打羽毛球","游泳"]}
{"id":"1004","name":"hanmeimei","dept":{"deptId":"A04","dept name":"营销部"},"xq":["游泳","跑步"]}
```

方式一：整个json字符串作为一列

```sql
--整个json作为一列
create table test1(line string);


--查询示例
select get_json_object(line,"$.name") from test1;
--返回
lisi
wangwu
zhaoliu
hanmeimei

--查询示例
select get_json_object(line,"$.xq[0]") from test1;
--返回
打篮球
看书
打羽毛球
游泳


--查看内建的json函数
desc function extended get_json_object;

"get_json_object(json_txt, path) - Extract a json object from path "
"Extract json object from a json string based on json path specified, and return json string of the extracted json object. It will return null if the input json string is invalid."
A limited version of JSONPath supported:
  $   : Root object
  .   : Child operator
  []  : Subscript operator for array
  *   : Wildcard for []
Syntax not supported that's worth noticing:
  ''  : Zero length string as key
  ..  : Recursive descent
  &amp;#064;   : Current object/element
  ()  : Script expression
  ?() : Filter (script) expression.
"  [,] : Union operator"
  [start:end:step] : array slice operator
""
Function class:org.apache.hadoop.hive.ql.udf.UDFJson
Function type:BUILTIN





```

方式二：拆解json到各个column中

```sql
--表的字段名应该和json的一级属性保持一致


--hive复杂数据类型
--array,map,struct
array
	类型定义：array<元素的类型>
	对象的创建：array(元素1，元素2...)  select array(1,7,5,6);  返回   [1,7,5,6]
	值的获取: select array(1,7,5,6)[0];
map
	类型定义：map<k的类型，v的类型>
	对象的创建:map(k1,v1,k2,v2...) select map('name','lisi','age',20); 返回  {"name":"lisi","age":"20"}
	值的获取:select map('name','lisi','age',20)['age'];
	获取所有的key: select map_keys(map('name','lisi','age',20));
	获取所有的value: select map_values(map('name','lisi','age',20));
struct
	类型定义：struct<属性名1:类型，属性名2:类型,....>
	对象的创建:
		1、struct('属性值1','属性值2')  这种方式属性名是默认的 select struct('lisi',20); 返回  {"col1":"lisi","col2":20}
		2、named_struct(属性名1,属性值1,属性名2,属性值2...)  select named_struct('name','lisi','age',20); 返回 {"name":"lisi","age":20}
	值的获取: select named_struct('name','lisi','age',20).age;



--建表语句
create table test2(
    id string,
    name string,
    dept struct<deptId:string,dept_name:string>,
    xq array<string>
)
row format serde 'org.apache.hadoop.hive.serde2.JsonSerDe';

select * from test2;
--返回：
1001,lisi,"{""deptid"":null,""dept_name"":null}","[""打篮球"",""打游戏""]"
1002,wangwu,"{""deptid"":null,""dept_name"":null}","[""看书"",""上网""]"
1003,zhaoliu,"{""deptid"":null,""dept_name"":null}","[""打羽毛球"",""游泳""]"
1004,hanmeimei,"{""deptid"":null,""dept_name"":null}","[""游泳"",""跑步""]"

		
```

#### 增量表建表实例

##### 原始数据

```json
{
	"op": "c",
	"after": {
		"is_deleted": "0",
		"create_time": "2023-01-11T13:54:07Z",
		"weight": 3.00,
		"cargo_type": "74005",
		"id": 12019,
		"order_id": "12021"
	},
	"source": {
		"server_id": 1,
		"version": "1.6.4.Final",
		"file": "mysql-bin.000009",
		"connector": "mysql",
		"pos": 59343585,
		"name": "mysql_binlog_source",
		"row": 0,
		"ts_ms": 1688552407000,
		"snapshot": "false",
		"db": "tms01",
		"table": "order_cargo"
	},
	"ts": 1673346007000
};
```

```sql
--建表语句
create external table ods_order_cargo_inc(
    op string,
    after struct<id:bigint,order_id:string,cargo_type:string,weight:decimal(16,2),create_time:string,is_deleted:string>,
    before struct<id:bigint,order_id:string,cargo_type:string,weight:decimal(16,2),create_time:string,is_deleted:string>,
    ts bigint
) comment '订单物流'
partitioned by (dt string)
row format serde 'org.apache.hadoop.hive.serde2.JsonSerDe'
location '/origin_data/tms/ods_order_cargo_inc';

load data inpath '/origin_data/tms/order_cargo_inc/2023-01-10/' overwrite into table ods_order_cargo_inc partition (dt="2023-01-10");
```

##### 最终所有的建表语句

```sql
drop table if exists ods_order_info_inc;
create external table ods_order_info_inc(
  `op` string comment '操作类型',
  `after` struct<`id`:bigint,`order_no`:string,`status`:string,`collect_type`:string,`user_id`:bigint,`receiver_complex_id`:bigint,`receiver_province_id`:string,`receiver_city_id`:string,`receiver_district_id`:string,`receiver_address`:string,`receiver_name`:string,`sender_complex_id`:bigint,`sender_province_id`:string,`sender_city_id`:string,`sender_district_id`:string,`sender_name`:string,`payment_type`:string,`cargo_num`:bigint,`amount`:decimal(16,2),`estimate_arrive_time`:string,`distance`:decimal(16,2),`create_time`:string,`update_time`:string,`is_deleted`:string> comment '修改或插入后的数据',
  `before` struct<`id`:bigint,`order_no`:string,`status`:string,`collect_type`:string,`user_id`:bigint,`receiver_complex_id`:bigint,`receiver_province_id`:string,`receiver_city_id`:string,`receiver_district_id`:string,`receiver_address`:string,`receiver_name`:string,`sender_complex_id`:bigint,`sender_province_id`:string,`sender_city_id`:string,`sender_district_id`:string,`sender_name`:string,`payment_type`:string,`cargo_num`:bigint,`amount`:decimal(16,2),`estimate_arrive_time`:string,`distance`:decimal(16,2),`create_time`:string,`update_time`:string,`is_deleted`:string> comment '修改前的数据',
  `ts` bigint comment '时间戳'
) comment '运单表'
	partitioned by (`dt` string comment '统计日期')
	ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.JsonSerDe'
	location '/warehouse/tms/ods/ods_order_info_inc';
--7.2 运单明细表（增量表）
drop table if exists ods_order_cargo_inc;
create external table ods_order_cargo_inc(
	`op` string comment '操作类型',
	`after` struct<`id`:bigint,`order_id`:string,`cargo_type`:string,`volume_length`:bigint,`volume_width`:bigint,`volume_height`:bigint,`weight`:decimal(16,2),`create_time`:string,`update_time`:string,`is_deleted`:string> comment '插入或修改后的数据',
	`before` struct<`id`:bigint,`order_id`:string,`cargo_type`:string,`volumn_length`:bigint,`volumn_width`:bigint,`volumn_height`:bigint,`weight`:decimal(16,2),`create_time`:string,`update_time`:string,`is_deleted`:string> comment '修改前的数据',
	`ts` bigint comment '时间戳'
) comment '运单明细表'
	partitioned by (`dt` string comment '统计日期')
	ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.JsonSerDe'
	location '/warehouse/tms/ods/ods_order_cargo_inc';
--7.3 运输任务表（增量表）
drop table if exists ods_transport_task_inc;
create external table ods_transport_task_inc(
	`op` string comment '操作类型',
	`after` struct<`id`:bigint,`shift_id`:bigint,`line_id`:bigint,`start_org_id`:bigint,`start_org_name`:string,`end_org_id`:bigint,`end_org_name`:string,`status`:string,`order_num`:bigint,`driver1_emp_id`:bigint,`driver1_name`:string,`driver2_emp_id`:bigint,`driver2_name`:string,`truck_id`:bigint,`truck_no`:string,`actual_start_time`:string,`actual_end_time`:string,`actual_distance`:decimal(16,2),`create_time`:string,`update_time`:string,`is_deleted`:string> comment '插入或修改后的数据',
	`before` struct<`id`:bigint,`shift_id`:bigint,`line_id`:bigint,`start_org_id`:bigint,`start_org_name`:string,`end_org_id`:bigint,`end_org_name`:string,`status`:string,`order_num`:bigint,`driver1_emp_id`:bigint,`driver1_name`:string,`driver2_emp_id`:bigint,`driver2_name`:string,`truck_id`:bigint,`truck_no`:string,`actual_start_time`:string,`actual_end_time`:string,`actual_distance`:decimal(16,2),`create_time`:string,`update_time`:string,`is_deleted`:string> comment '修改前的数据',
	`ts` bigint comment '时间戳'
) comment '运输任务表'
	partitioned by (`dt` string comment '统计日期')
	ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.JsonSerDe'
	location '/warehouse/tms/ods/ods_transport_task_inc';
--7.4 运单机构中转表（增量表）
drop table if exists ods_order_org_bound_inc;
create external table ods_order_org_bound_inc(
	`op` string comment '操作类型',
	`after` struct<`id`:bigint,`order_id`:bigint,`org_id`:bigint,`status`:string,`inbound_time`:string,`inbound_emp_id`:bigint,`sort_time`:string,`sorter_emp_id`:bigint,`outbound_time`:string,`outbound_emp_id`:bigint,`create_time`:string,`update_time`:string,`is_deleted`:string> comment '插入或修改后的数据',
	`before` struct<`id`:bigint,`order_id`:bigint,`org_id`:bigint,`status`:string,`inbound_time`:string,`inbound_emp_id`:bigint,`sort_time`:string,`sorter_emp_id`:bigint,`outbound_time`:string,`outbound_emp_id`:bigint,`create_time`:string,`update_time`:string,`is_deleted`:string> comment '修改之前的数据',
	`ts` bigint comment '时间戳'
) comment '运单机构中转表'
	partitioned by (`dt` string comment '统计日期')
	ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.JsonSerDe'
	location '/warehouse/tms/ods/ods_order_org_bound_inc';
--7.5 用户信息表（增量表）
drop table if exists ods_user_info_inc;
create external table ods_user_info_inc(
	`op` string comment '操作类型',
	`after` struct<`id`:bigint,`login_name`:string,`nick_name`:string,`passwd`:string,`real_name`:string,`phone_num`:string,`email`:string,`user_level`:string,`birthday`:string,`gender`:string,`create_time`:string,`update_time`:string,`is_deleted`:string> comment '插入或修改后的数据',
	`before` struct<`id`:bigint,`login_name`:string,`nick_name`:string,`passwd`:string,`real_name`:string,`phone_num`:string,`email`:string,`user_level`:string,`birthday`:string,`gender`:string,`create_time`:string,`update_time`:string,`is_deleted`:string> comment '修改之前的数据',
	`ts` bigint comment '时间戳'
) comment '用户信息表'
	partitioned by (`dt` string comment '统计日期')
	ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.JsonSerDe'
	location '/warehouse/tms/ods/ods_user_info_inc';
--7.6 用户地址表（增量表）
drop table if exists ods_user_address_inc;
create external table ods_user_address_inc(
	`op` string comment '操作类型',
	`after` struct<`id`:bigint,`user_id`:bigint,`phone`:string,`province_id`:bigint,`city_id`:bigint,`district_id`:bigint,`complex_id`:bigint,`address`:string,`is_default`:string,`create_time`:string,`update_time`:string,`is_deleted`:string> comment '插入或修改后的数据',
	`before` struct<`id`:bigint,`user_id`:bigint,`phone`:string,`province_id`:bigint,`city_id`:bigint,`district_id`:bigint,`complex_id`:bigint,`address`:string,`is_default`:string,`create_time`:string,`update_time`:string,`is_deleted`:string> comment '修改之前的数据',
	`ts` bigint comment '时间戳'
) comment '用户地址表'
	partitioned by (`dt` string comment '统计日期')
	ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.JsonSerDe'
	location '/warehouse/tms/ods/ods_user_address_inc';
--7.7 小区表（全量表）
drop table if exists ods_base_complex_full;
create external table ods_base_complex_full(
	`id` bigint comment '小区ID',
	`complex_name` string comment '小区名称',
	`province_id` bigint comment '省份ID',
	`city_id` bigint comment '城市ID',
	`district_id` bigint comment '区（县）ID',
	`district_name` string comment '区（县）名称',
	`create_time` string comment '创建时间',
	`update_time` string comment '更新时间',
	`is_deleted` string comment '是否删除'
) comment '小区表'
	partitioned by (`dt` string comment '统计日期')
	row format delimited fields terminated by '\t'
	null defined as ''
	location '/warehouse/tms/ods/ods_base_complex_full';
--7.8 字典表（全量表）
drop table if exists ods_base_dic_full;
create external table ods_base_dic_full(
    `id` bigint comment '编号（主键）',
    `parent_id` bigint comment '父级编号',
    `name` string comment '名称',
    `dict_code` string comment '编码',
    `create_time` string comment '创建时间',
    `update_time` string comment '更新时间',
    `is_deleted` string comment '是否删除'
) COMMENT '编码字典表'
    PARTITIONED BY (`dt` STRING)
    ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t'
    NULL DEFINED AS ''
    location '/warehouse/tms/ods/ods_base_dic_full/';
--7.9 地区表（全量表）
drop table if exists ods_base_region_info_full;
create external table ods_base_region_info_full(
	`id` bigint COMMENT '地区ID',
	`parent_id` bigint COMMENT '父级地区ID',
	`name` string COMMENT '地区名称',
	`dict_code` string COMMENT '编码（行政级别）',
	`short_name` string COMMENT '简称',
	`create_time` string COMMENT '创建时间',
	`update_time` string COMMENT '更新时间',
	`is_deleted` tinyint COMMENT '删除标记（0:不可用 1:可用）'
) comment '地区表'
	partitioned by (`dt` string comment '统计日期')
	row format delimited fields terminated by '\t'
	null defined as ''
	location '/warehouse/tms/ods/ods_base_region_info_full';
--7.10 机构表（全量表）
drop table if exists ods_base_organ_full;
create external table ods_base_organ_full(
	`id` bigint COMMENT '机构ID',
	`org_name` string COMMENT '机构名称',
	`org_level` bigint COMMENT '机构等级（1为转运中心，2为转运站）',
	`region_id` bigint COMMENT '地区ID，1级机构为city ,2级机构为district',
	`org_parent_id` bigint COMMENT '父级机构ID',
	`points` string COMMENT '多边形经纬度坐标集合',
	`create_time` string COMMENT '创建时间',
	`update_time` string COMMENT '更新时间',
	`is_deleted` string COMMENT '删除标记（0:不可用 1:可用）'
) comment '机构表'
	partitioned by (`dt` string comment '统计日期')
	row format delimited fields terminated by '\t'
	null defined as ''
	location '/warehouse/tms/ods/ods_base_organ_full';
--7.11 快递员信息表（全量表）
drop table if exists ods_express_courier_full;
create external table ods_express_courier_full(
	`id` bigint COMMENT '快递员ID',
	`emp_id` bigint COMMENT '员工ID',
	`org_id` bigint COMMENT '所属机构ID',
	`working_phone` string COMMENT '工作电话',
	`express_type` string COMMENT '快递员类型（收货；发货）',
	`create_time` string COMMENT '创建时间',
	`update_time` string COMMENT '更新时间',
	`is_deleted` string COMMENT '删除标记（0:不可用 1:可用）'
) comment '快递员信息表'
	partitioned by (`dt` string comment '统计日期')
	row format delimited fields terminated by '\t'
	null defined as ''
	location '/warehouse/tms/ods/ods_express_courier_full';
--7.12 快递员小区关联表
drop table if exists ods_express_courier_complex_full;
create external table ods_express_courier_complex_full(
	`id` bigint COMMENT '主键ID',
	`courier_emp_id` bigint COMMENT '快递员ID',
	`complex_id` bigint COMMENT '小区ID',
	`create_time` string COMMENT '创建时间',
	`update_time` string COMMENT '更新时间',
	`is_deleted` string COMMENT '删除标记（0:不可用 1:可用）' 
) comment '快递员小区关联表'
	partitioned by (`dt` string comment '统计日期')
	row format delimited fields terminated by '\t'
	null defined as ''
	location '/warehouse/tms/ods/ods_express_courier_complex_full';
--7.13 员工表（全量表）
drop table if exists ods_employee_info_full;
create external table ods_employee_info_full(
	`id` bigint COMMENT '员工ID',
	`username` string COMMENT '用户名',
	`password` string COMMENT '密码',
	`real_name` string COMMENT '真实姓名',
	`id_card` string COMMENT '身份证号',
	`phone` string COMMENT '手机号',
	`birthday` string COMMENT '生日',
	`gender` string COMMENT '性别',
	`address` string COMMENT '地址',
	`employment_date` string COMMENT '入职日期',
	`graduation_date` string COMMENT '离职日期',
	`education` string COMMENT '学历',
	`position_type` string COMMENT '岗位类别',
	`create_time` string COMMENT '创建时间',
	`update_time` string COMMENT '更新时间',
	`is_deleted` string COMMENT '删除标记（0:不可用 1:可用）'
) comment '员工表'
	partitioned by (`dt` string comment '统计日期')
	row format delimited fields terminated by '\t'
	null defined as ''
	location '/warehouse/tms/ods/ods_employee_info_full';
--7.14 班次表（全量表）
drop table if exists ods_line_base_shift_full;
create external table ods_line_base_shift_full(
	`id` bigint COMMENT '班次ID',
	`line_id` bigint COMMENT '线路ID',
	`start_time` string COMMENT '班次开始时间',
	`driver1_emp_id` bigint COMMENT '第一司机',
	`driver2_emp_id` bigint COMMENT '第二司机',
	`truck_id` bigint COMMENT '卡车',
	`pair_shift_id` bigint COMMENT '配对班次(同一辆车一去一回的另一班次)',
	`is_enabled` string COMMENT '状态 0：禁用 1：正常',
	`create_time` string COMMENT '创建时间',
	`update_time` string COMMENT '更新时间',
	`is_deleted` string COMMENT '删除标记（0:不可用 1:可用）'
) comment '班次表'
	partitioned by (`dt` string comment '统计日期')
	row format delimited fields terminated by '\t'
	null defined as ''
	location '/warehouse/tms/ods/ods_line_base_shift_full';
--7.15 运输线路表（全量表）
drop table if exists ods_line_base_info_full;
create external table ods_line_base_info_full(
	`id` bigint COMMENT '线路ID',
	`name` string COMMENT '线路名称',
	`line_no` string COMMENT '线路编号',
	`line_level` string COMMENT '线路级别',
	`org_id` bigint COMMENT '所属机构',
	`transport_line_type_id` string COMMENT '线路类型',
	`start_org_id` bigint COMMENT '起始机构ID',
	`start_org_name` string COMMENT '起始机构名称',
	`end_org_id` bigint COMMENT '目标机构ID',
	`end_org_name` string COMMENT '目标机构名称',
	`pair_line_id` bigint COMMENT '配对线路ID',
	`distance` decimal(10,2) COMMENT '预估里程',
	`cost` decimal(10,2) COMMENT '实际里程',
	`estimated_time` bigint COMMENT '预计时间（分钟）',
	`status` string COMMENT '状态 0：禁用 1：正常',
	`create_time` string COMMENT '创建时间',
	`update_time` string COMMENT '更新时间',
	`is_deleted` string COMMENT '删除标记（0:不可用 1:可用）'
) comment '运输线路表'
	partitioned by (`dt` string comment '统计日期')
	row format delimited fields terminated by '\t'
	null defined as ''
	location '/warehouse/tms/ods/ods_line_base_info_full';
--7.16 司机信息表（全量表）
drop table if exists ods_truck_driver_full;
create external table ods_truck_driver_full(
	`id` bigint COMMENT '司机信息ID',
	`emp_id` bigint COMMENT '员工ID',
	`org_id` bigint COMMENT '所属机构ID',
	`team_id` bigint COMMENT '所属车队ID',
	`license_type` string COMMENT '准驾车型',
	`init_license_date` string COMMENT '初次领证日期',
	`expire_date` string COMMENT '有效截止日期',
	`license_no` string COMMENT '驾驶证号',
	`license_picture_url` string COMMENT '驾驶证图片链接',
	`is_enabled` tinyint COMMENT '状态 0：禁用 1：正常',
	`create_time` string COMMENT '创建时间',
	`update_time` string COMMENT '更新时间',
	`is_deleted` string COMMENT '删除标记（0:不可用 1:可用）'
) comment '司机信息表'
	partitioned by (`dt` string comment '统计日期')
	row format delimited fields terminated by '\t'
	null defined as ''
	location '/warehouse/tms/ods/ods_truck_driver_full';
--7.17 卡车信息表（全量表）
drop table if exists ods_truck_info_full;
create external table ods_truck_info_full(
	`id` bigint COMMENT '卡车ID',
	`team_id` bigint COMMENT '所属车队ID',
	`truck_no` string COMMENT '车牌号码',
	`truck_model_id` string COMMENT '型号',
	`device_gps_id` string COMMENT 'GPS设备ID',
	`engine_no` string COMMENT '发动机编码',
	`license_registration_date` string COMMENT '注册时间',
	`license_last_check_date` string COMMENT '最后年检日期',
	`license_expire_date` string COMMENT '失效日期',
	`picture_url` string COMMENT '图片链接',
	`is_enabled` tinyint COMMENT '状态 0：禁用 1：正常',
	`create_time` string COMMENT '创建时间',
	`update_time` string COMMENT '更新时间',
	`is_deleted` string COMMENT '删除标记（0:不可用 1:可用）'
) comment '卡车信息表'
	partitioned by (`dt` string comment '统计日期')
	row format delimited fields terminated by '\t'
	null defined as ''
	location '/warehouse/tms/ods/ods_truck_info_full';
--7.18 卡车型号表（全量表）
drop table if exists ods_truck_model_full;
create external table ods_truck_model_full(
	`id` bigint COMMENT '型号ID',
	`model_name` string COMMENT '型号名称',
	`model_type` string COMMENT '型号类型',
	`model_no` string COMMENT '型号编码',
	`brand` string COMMENT '品牌',
	`truck_weight` decimal(16,2) COMMENT '整车重量（吨）',
	`load_weight` decimal(16,2) COMMENT '额定载重（吨）',
	`total_weight` decimal(16,2) COMMENT '总质量（吨）',
	`eev` string COMMENT '排放标准',
	`boxcar_len` decimal(16,2) COMMENT '货箱长（m）',
	`boxcar_wd` decimal(16,2) COMMENT '货箱宽（m）',
	`boxcar_hg` decimal(16,2) COMMENT '货箱高（m）',
	`max_speed` bigint COMMENT '最高时速（千米/时）',
	`oil_vol` bigint COMMENT '油箱容积（升）',
	`create_time` string COMMENT '创建时间',
	`update_time` string COMMENT '更新时间',
	`is_deleted` string COMMENT '删除标记（0:不可用 1:可用）'
) comment '卡车型号表'
	partitioned by (`dt` string comment '统计日期')
	row format delimited fields terminated by '\t'
	null defined as ''
	location '/warehouse/tms/ods/ods_truck_model_full';
--7.19 车队信息表（全量表）
drop table if exists ods_truck_team_full;
create external table ods_truck_team_full(
	`id` bigint COMMENT '车队ID',
	`name` string COMMENT '车队名称',
	`team_no` string COMMENT '车队编号',
	`org_id` bigint COMMENT '所属机构',
	`manager_emp_id` bigint COMMENT '负责人',
	`create_time` string COMMENT '创建时间',
	`update_time` string COMMENT '更新时间',
	`is_deleted` string COMMENT '删除标记（0:不可用 1:可用）'
) comment '车队信息表'
	partitioned by (`dt` string comment '统计日期')
	row format delimited fields terminated by '\t'
	null defined as ''
	location '/warehouse/tms/ods/ods_truck_team_full';

```

