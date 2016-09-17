create database if not exists `securities` character set utf8;

use securities;

-- ====================================
-- Table definitions
-- ====================================

create table if not exists `securities_code` (
       `code` varchar(6) primary key, -- 证券代码
       `market` varchar(10) not null, -- 证券市场名称
       `country` varchar(5) not null  -- 证券市场所在国家
);
create table if not exists `securities_dividend` (
       `code` varchar(6) not null, -- 证券代码
       `year` smallint not null,   -- 财务年度
       `eps` decimal(10,4) not null, -- 每股收益（元）
       `div1` tinyint unsigned not null, -- 每10股送股（股）
       `div2` tinyint unsigned not null, -- 每10股转增（股）
       `div3` decimal(10,4) unsigned not null, -- 每10股现金分红（元）
       `reg_time` date not null, -- 登记日
       `div_time` date not null, -- 除权日
       primary key (code, year)
);
create table if not exists `securities_dividend_plan` (
       `code` varchar(6) not null, -- 证券代码
       `year` smallint not null,   -- 财务年度
       `eps` decimal(10,4) not null, -- 每股收益（元）
       `div1` tinyint unsigned not null, -- 每10股送股（股）
       `div2` tinyint unsigned not null, -- 每10股转增（股）
       `div3` decimal(10,4) unsigned not null, -- 每10股现金分红（元）
       primary key (code, year)
);
create table if not exists `securities_day_quote` (
       `code` varchar(6) not null primary key, -- 证券代码
       `time` date not null, -- 日期
       `per` decimal(10,4) not null, -- 市盈率
       `pbr` decimal(10,4) not null, -- 市净率
       `price` decimal(10,4) not null, -- 价格（元）
       `amp` decimal(10,4) not null, -- 振幅
       `vol` int not null -- 成交量(手)
);
create table if not exists `securities_day_quote_history` (
       `code` varchar(6) not null, -- 证券代码
       `time` date not null, -- 日期
       `close_price` decimal(10,4) not null, -- 价格（元）
       primary key (code, time)
);
create table if not exists `securities_major_financial_kpi` (
       `code` varchar(6) not null, -- 证券代码
       `time` date not null, -- 报告期
       `MFRation28` decimal(10,4), -- 基本每股收益（元）
       `MFRation18` decimal(10,4), -- 每股净资产（元）
       `MFRation20` decimal(10,4), -- 每股经营活动产生的现金流量净额（元）
       `MFRation22` decimal(10,4), -- 净资产收益率加权
       `MFRation10` decimal(20,4), -- 主营业务收入（万元）
       `MFRation4`  decimal(20,4), -- 主营业务利润（万元）
       `MFRation5`  decimal(20,4), -- 营业利润（万元）
       `MFRation6`  decimal(20,4), -- 投资收益（万元）
       `MFRation7`  decimal(20,4), -- 营业外收支净额（万元）
       `MFRation1`  decimal(20,4), -- 利润总额（万元）
       `MFRation2`  decimal(20,4), -- 净利润（万元）
       `MFRation3`  decimal(20,4), -- 净利润(扣除非经常性损益后)（万元）
       `MFRation8`  decimal(20,4), -- 经营活动产生的现金流量净额（万元）
       `MFRation9`  decimal(20,4), -- 现金及现金等价物净增加额（万元）
       `MFRation12`  decimal(20,4),-- 总资产（万元）
       `MFRation13`  decimal(20,4), -- 股东权益不含少数股东权益（万元）
       primary key (code, time)

);
create table if not exists `securities_stock_structure` (
       `code` varchar(6) not null, -- 证券代码
       `time` date not null, -- 报告期
       `change_reason` varchar(20), -- 变更原因
       `total_share` decimal(20,2), -- 总股份（万股）
       `share_in_circulate` decimal(20,2), -- 流通股份（万股）
       `share_in_circulate_a` decimal(20,2), -- 流通A股股份（万股）
       `share_in_circulate_h` decimal(20,2), -- 流通H股股份（万股）
       primary key (code, time)
);
create table if not exists `securities_transaction` (
       `id` int unsigned not null primary key auto_increment,
       `time` date not null, -- 成交日期
       `code` varchar(6), -- 证券代码
       `price` decimal(10,4), -- 成交价格（元）
       `vol` decimal(20,2), -- 成交量(股)
       `tname` varchar(10), -- 业务名称
       `amount` decimal(20,4), -- 发生金额（元）
       `balance` decimal(20,4) -- 剩余金额（元）
);
create table if not exists `securities_holding` (
       `id` int unsigned not null primary key auto_increment,
       `time` date not null, -- 日期
       `code` varchar(6), -- 证券代码
       `price` decimal(10,4), -- 价格（元）
       `cost` decimal(10,4), -- 成本价格（元）
       `vol` decimal(20,2) -- 存量(股)
);
create table if not exists `cash_holding` (
       `id` int unsigned not null primary key auto_increment,
       `time` date not null, -- 日期
       `amount` decimal(20,4) -- 金额（元）
);


-- ====================================
-- View definitions
-- ====================================

-- dividend_from_2010 自2010年度以来有分红的股票
-- create or replace view dividend_from_2010 as
-- select
--   code,
--   count(year) years
-- from securities_dividend
-- where year >=2010
-- group by code;

-- dividend_2010_5 自2010年度以来分红等于或超过5次的股票（也就是连续5年盈利的企业）
-- create or replace view dividend_2010_5 as
-- select
--   d.code,
--   d.years,
--   c.market
-- from dividend_from_2010 d
-- join securities_code c on d.code=c.code
-- where d.years >=5
-- order by years;

-- short_list_01 当前市盈率在1至10之间，且自2010年度以来分红等于或超过5次的股票代码（连续5年盈利，且市盈率在10以下的企业）
-- create or replace view short_list_01 as
-- select
--   d.code,
--   q.per,
--   q.pbr
-- from securities_day_quote q
-- join dividend_2010_5 d on d.code = q.code
-- where q.per >= 1 and q.per <= 10 and q.time = '2016-07-01';

-- short_list_02 当前市盈率在1至10之间，市净率小于1，且自2010年度以来分红等于或超过5次的股票代码（连续5年盈利，且市盈率在10以下的企业）
-- create or replace view short_list_02 as
-- select * from short_list_01 where pbr < 1 order by pbr;

-- short_list_03 当前市盈率在1至20之间，且自2010年度以来分红等于或超过5次，净资产收益率超过10%，每股分红与股价比率最高的前30个股票
-- create or replace view short_list_03 as
-- select
--   d.code 代码,
--   q.per 市盈率,
--   q.pbr 市净率,
--   dp.eps 每股盈利,
--   dp.div3/10.0 每股分红,
--   dp.div3/10.0/dp.eps 分红比盈利,
--   dp.div3/q.price/10.0 分红比价格,
--   kpi.MFRation22 净资产收益率
-- from securities_day_quote q
-- join dividend_2010_5 d on d.code = q.code
-- join securities_dividend dp on d.code = dp.code
-- join securities_major_financial_kpi kpi on d.code = kpi.code
-- where q.per >= 1 and q.per <= 20 and q.time='2016-07-01' and kpi.MFRation22 >= 10 and kpi.time = '2015-12-31'
-- order by 分红比价格 desc
-- limit 30;

-- profitibility 公司盈利能力（资产收益率，净资产收益率）
-- create or replace view profitibility as select
--   code,
--   time,
--   MFRation2 / MFRation12 roa,
--   MFRation2 / MFRation13 roe
-- from securities_major_financial_kpi;


-- achievement_soldout_subtotal 已结实盈(个股)，曾经持有，目前清仓的证券
-- create or replace view achievement_soldout_subtotal as
-- select
--   code,
--   sum(amount) achievement
-- from securities_transaction
-- where tname = '证券买入' or tname = '证券卖出' or tname = '红股入账'
-- group by code
-- having sum(vol)=0;

-- achievement_soldout_total 已结实盈(汇总)，曾经持有，目前清仓的证券
-- create or replace view achievement_soldout_total as
-- select
--   sum(achievement) achievement
-- from achievement_soldout_subtotal;

-- achievement_dividend_subtotal 已结实盈(个股)，分红
-- create or replace view achievement_dividend_subtotal as
-- select
--   code,
--   sum(amount) achievement
-- from securities_transaction
-- where tname = '股息入账' or tname = '股息红利税补缴'
-- group by code;

-- achievement_dividend_subtotal 已结实盈(汇总)，分红
-- create or replace view achievement_dividend_total as
-- select
--   sum(achievement) achievement
-- from achievement_dividend_subtotal;


-- ====================================
-- Stored procedure definitions
-- ====================================


-- 计算指定时期投资账户的投资盈利P：
--     期初持有证券的总市值 S0
--     期初持有现金 C0
--     期末持有证券的总市值 S1
--     期末持有现金 C1
--     期间银证转帐流入资金净额 Cn = Ci - Co (Ci: 流入，Co: 流出)
--     P = S1 + C1 - S0 - C0 - Cn
-- 计算指定时期的已结实盈P1和浮动盈亏P2:
--     已结实盈又可分为：
--         期末清仓证券所获价差盈利:
--             期初已持有
--             期间购入
--         证券分红（不包括红股）
--     浮动盈亏：
--         期末持有的证券：
--             期初已持有：期初持有数量，期初价格
--             期间购入：每次购买数量和购买价格
--             所得红股


-- achievement_soldout_subtotal:
-- 已结实盈(个股)，曾经持有，目前清仓的证券
drop procedure if exists achievement_soldout_subtotal;
delimiter //
create procedure achievement_soldout_subtotal (in start_time date, in end_time date)
begin
declare count1 int;
declare count2 int;
select count(*) from securities_holding where time = start_time into count1;
select count(*) from securities_holding where time = end_time into count2;
-- securities_holding应该明确指示证券在start_time和end_time的证券持有状态
if count1 = 0 or count2 = 0 then
  signal sqlstate '45000' set message_text = 'securities_holding contains not data for the given time range.';
end if;

drop temporary table if exists achievement_soldout_subtotal_tmp;
create temporary table achievement_soldout_subtotal_tmp
  select
    code,
    sum(amount) achievement
  from securities_transaction
  where
    code in (
      select code from securities_holding where time = start_time and code not in (select code from securities_holding where time = end_time)
      union
      select code from securities_transaction where tname = '证券买入' or tname = '证券卖出' or tname = '红股入账' group by code having sum(vol)=0)
    and
    (tname = '证券买入' or tname = '证券卖出' or tname = '红股入账')
  group by code;
select * from achievement_soldout_subtotal_tmp;
end;
//
delimiter ;

-- achievement_soldout_total:
-- 已结实盈(汇总)，曾经持有，目前清仓的证券
drop procedure if exists achievement_soldout_total;
delimiter //
create procedure achievement_soldout_total (in start_time date, in end_time date)
begin
call achievement_soldout_subtotal(start_time, end_time);
select sum(achievement) from achievement_soldout_subtotal_tmp;
end;
//
delimiter ;

-- achievement_dividend_subtotal
-- 已结实盈(个股)，分红
drop procedure if exists achievement_dividend_subtotal;
delimiter //
create procedure achievement_dividend_subtotal (in start_time date, in end_time date)
begin
drop temporary table if exists achievement_dividend_subtotal_tmp;
create temporary table achievement_dividend_subtotal_tmp
  select
    code,
    sum(amount) achievement
  from securities_transaction
  where
    (tname = '股息入账' or tname = '股息红利税补缴')
    and
    (time >= start_time and time <= end_time)
  group by code;
select * from achievement_dividend_subtotal_tmp;
end;
//
delimiter ;

-- achievement_dividend_total
-- 已结实盈(汇总)，分红
drop procedure if exists achievement_dividend_total;
delimiter //
create procedure achievement_dividend_total (in start_time date, in end_time date)
begin
call achievement_dividend_subtotal(start_time, end_time);
select sum(achievement) from achievement_dividend_subtotal_tmp;
end;
//
delimiter ;


-- short_list
-- 条件选股
-- 从给定“分红起始年份”（含）起有不少于给定“分红年数“的证券
-- 市盈率在给定区间的证券（在securities_day_quote的最新日期上）
-- 市净率在给定区间的证券（在securities_day_quote的最新日期上）
-- 净资产收益率在给定区间的证券（在securities_major_financial_kpi的最新日期上）
-- 根据上年度分红对股价的率比（在securities_day_quote的最新日期上）降序排列取给定row_limit条记录
drop procedure if exists short_list;
delimiter //
create procedure short_list (
       in div_inception_year smallint, -- 分红起始年份
       in div_years tinyint, -- 分红年数
       in per_l decimal(4,2), -- 市盈率下限，基于securities_day_quote中最新日期
       in per_u decimal(4,2), -- 市盈率上限，基于securities_day_quote中最新日期
       in pbr_l decimal(4,2), -- 市净率下限，基于securities_day_quote中最新日期
       in pbr_u decimal(4,2), -- 市净率上限，基于securities_day_quote中最新日期
       in roe_l decimal(4,2), -- 净资产收益率下限，基于securities_major_financial_kpi中最新日期
       in roe_u decimal(4,2), -- 净资产收益率上限，基于securities_major_financial_kpi中最新日期
       in row_limit tinyint -- 返回满足条件的证券数量上限
       )
begin
declare quote_date date;
declare kpi_date date;
select max(time) from securities_day_quote into quote_date;
select max(time) from securities_major_financial_kpi where time like '%-12-31' into kpi_date;
select
  d.code 代码,
  q.per 市盈率,
  q.pbr 市净率,
  d.eps 每股盈利,
  d.div3/10.0 每股分红,
  d.div3/10.0/d.eps 分红比盈利,
  d.div3/q.price/10.0 分红比价格,
  k.MFRation22 净资产收益率
from securities_dividend d
join securities_day_quote q on q.code = d.code
join securities_major_financial_kpi k on k.code = d.code
where
  q.time = quote_date and k.time = kpi_date
  and q.per >= per_l and q.per <= per_u
  and q.pbr >= pbr_l and q.pbr <= pbr_u
  and k.MFRation22 >= roe_l and k.MFRation22 <= roe_u
  and d.year >= (div_inception_year + div_years - 1)
  and d.code in (
    select code from (
      select
        code,
        count(year)
      from securities_dividend
      where year >= div_inception_year
      group by code
      having count(year) >= div_years) div_code)
order by 分红比价格 desc
limit row_limit;
end;
//
delimiter ;
