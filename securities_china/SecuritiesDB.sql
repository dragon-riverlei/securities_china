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



-- ====================================
-- View definitions
-- ====================================

-- dividend_from_2010 自2010年度以来有分红的股票
create or replace view dividend_from_2010 as
select
  code,
  count(year) years
from securities_dividend
where year >=2010
group by code;

-- dividend_2010_5 自2010年度以来分红等于或超过5次的股票（也就是连续5年盈利的企业）
create or replace view dividend_2010_5 as
select
  d.code,
  d.years,
  c.market
from dividend_from_2010 d
join securities_code c on d.code=c.code
where d.years >=5
order by years;

-- short_list_01 当前市盈率在1至10之间，且自2010年度以来分红等于或超过5次的股票代码（连续5年盈利，且市盈率在10以下的企业）
create or replace view short_list_01 as
select
  d.code,
  q.per,
  q.pbr
from securities_day_quote q
join dividend_2010_5 d on d.code = q.code
where q.per > 1 and q.per < 10;

-- short_list_02 当前市盈率在1至10之间，市净率小于1，且自2010年度以来分红等于或超过5次的股票代码（连续5年盈利，且市盈率在10以下的企业）
create or replace view short_list_02 as
select * from short_list_01 where pbr < 1 order by pbr;

-- short_list_03 当前市盈率在1至20之间，且自2010年度以来分红等于或超过5次，净资产收益率超过10%，每股分红与股价比率最高的前30个股票
create or replace view short_list_03 as
select
  d.code 代码,
  q.per 市盈率,
  q.pbr 市净率,
  dp.eps 每股盈利,
  dp.div3/10.0 每股分红,
  dp.div3/10.0/dp.eps 分红比盈利,
  dp.div3/q.price/10.0 分红比价格,
  kpi.MFRation22 净资产收益率
from securities_day_quote q
join dividend_2010_5 d on d.code = q.code
join securities_dividend_plan dp on d.code = dp.code
join securities_major_financial_kpi kpi on d.code = kpi.code
where q.per > 1 and q.per < 20 and q.time='2016-05-31' and kpi.MFRation22 > 10 and kpi.time = '2015-12-31'
order by 分红比价格 desc
limit 30;

-- profitibility 公司盈利能力（资产收益率，净资产收益率）
create or replace view profitibility as select
  code,
  time,
  MFRation2 / MFRation12 roa,
  MFRation2 / MFRation13 roe
from securities_major_financial_kpi
