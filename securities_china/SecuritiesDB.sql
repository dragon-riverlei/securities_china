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
create table if not exists `fund_type` (
       `id` int unsigned not null primary key auto_increment,
       `name` varchar(10) not null   -- 基金类型
);
create table if not exists `fund_code` (
       `code` varchar(6) primary key, -- 基金代码
       `name` varchar(20) not null,   -- 基金名称
       `type` int unsigned not null,   -- 基金类型
       foreign key (type)
               references fund_type(id)
               on delete restrict
);


-- ====================================
-- Stored procedure definitions
-- ====================================

-- transaction_soldout_subtotal:已结实盈(清仓个股)，曾经持有，目前清仓的证券
-- transaction_soldout_total:已结实盈(清仓汇总)，曾经持有，目前清仓的证券
-- transaction_dividend_subtotal:已结实盈(分红个股)，分红
-- transaction_dividend_total:已结实盈(分红汇总)，分红
-- transaction_holding_subtotal:浮盈（个股）
-- transaction_holding_total:浮盈（汇总）
-- investment_earning:投资收益（给定时间区间）
-- short_list:条件选股
-- short_list_code:条件选股，只返回代码
-- short_list_detail:条件选股，返回详细信息
-- short_list_detail_default:条件选股（使用缺省条件），返回详细信息
-- data_status:汇总目前数据库中所收集数据的状态


-- 计算指定时期投资账户的投资盈利P：
--     期初持有证券的总市值 S0
--     期初持有现金 C0
--     期末持有证券的总市值 S1
--     期末持有现金 C1
--     期间银证转帐流入资金净额 Cn = Ci - Co (Ci: 流入，Co: 流出)
--     P = S1 + C1 - S0 - C0 - Cn
-- 计算指定时期的已结实盈P1和浮动盈亏P2:
--     已结实盈又可分为：
--         期末清仓证券所获价差盈利
--         证券分红（不包括红股）
--     浮动盈亏：
--         期末持有的证券：
--             期初已持有：期初持有数量，期初价格
--             期间购入：每次购买数量和购买价格
--             所得红股


-- transaction_soldout_subtotal:
-- 已结实盈(清仓个股)，曾经持有，目前清仓的证券
-- 要分期初已持有和期初未持有
drop procedure if exists transaction_soldout_subtotal;
delimiter //
create procedure transaction_soldout_subtotal (in start_time date, in end_time date)
begin
declare count1 int;
declare count2 int;
select count(*) from securities_holding where time = start_time into count1;
select count(*) from securities_holding where time = end_time into count2;
-- securities_holding应该明确指示证券在start_time和end_time的证券持有状态
-- 如果在这两个时刻都没有持有任何证券，则code=None，price=cost=vol=0。
if count1 = 0 or count2 = 0 then
  signal sqlstate '45000' set message_text = 'securities_holding contains not data for the given time range.';
end if;

drop temporary table if exists transaction_soldout_subtotal_tmp;
create temporary table transaction_soldout_subtotal_tmp
  select  -- 1st select clause: 期初持有，期末清仓
    sd.code,
    st.amount - price * vol amount -- 期间交易金额 - 期初市值
  from securities_holding sd
  join (
    select
      code,
      sum(amount) amount
    from securities_transaction
    where time > start_time and time <= end_time
      and (tname = '证券买入' or tname = '证券卖出' or tname = '红股入账')
      and
        code in (
          select
            code
          from securities_holding
          where time = start_time
            and code not in (
                         select
                           code
                         from securities_holding
                         where time = end_time)
        )
    group by code
  ) st
  on sd.code = st.code
  where
    sd.time = start_time
  union
  select  -- 2nd select clause: 期初、期末均未持有，但期间曾持有
    code,
    sum(amount) amount
  from securities_transaction
  where time > start_time and time <= end_time
    and
      code not in (
        select
          code
        from securities_holding
        where (time = start_time or time = end_time) and code <> 'None')
    and
      (tname = '证券买入' or tname = '证券卖出' or tname = '红股入账')
  group by code;

select * from transaction_soldout_subtotal_tmp;
end;
//
delimiter ;

-- transaction_soldout_total:
-- 已结实盈(清仓汇总)，曾经持有，目前清仓的证券
drop procedure if exists transaction_soldout_total;
delimiter //
create procedure transaction_soldout_total (in start_time date, in end_time date)
begin
call transaction_soldout_subtotal(start_time, end_time);
select sum(amount) from transaction_soldout_subtotal_tmp;
end;
//
delimiter ;

-- transaction_dividend_subtotal
-- 已结实盈(分红个股)，分红
drop procedure if exists transaction_dividend_subtotal;
delimiter //
create procedure transaction_dividend_subtotal (in start_time date, in end_time date)
begin
drop temporary table if exists transaction_dividend_subtotal_tmp;
create temporary table transaction_dividend_subtotal_tmp
  select
    code,
    sum(amount) amount
  from securities_transaction
  where
    (time > start_time and time <= end_time)
    and
    (tname = '股息入账' or tname = '股息红利税补缴')
  group by code;
select * from transaction_dividend_subtotal_tmp;
end;
//
delimiter ;

-- transaction_dividend_total
-- 已结实盈(分红汇总)，分红
drop procedure if exists transaction_dividend_total;
delimiter //
create procedure transaction_dividend_total (in start_time date, in end_time date)
begin
call transaction_dividend_subtotal(start_time, end_time);
select sum(amount) from transaction_dividend_subtotal_tmp;
end;
//
delimiter ;

-- transaction_holding_sutotal
-- 浮盈（个股）
drop procedure if exists transaction_holding_subtotal;
delimiter //
create procedure transaction_holding_subtotal (in start_time date, in end_time date)
begin
declare count1 int;
declare count2 int;
select count(*) from securities_holding where time = start_time into count1;
select count(*) from securities_holding where time = end_time into count2;
-- securities_holding应该明确指示证券在start_time和end_time的证券持有状态
-- 如果在这两个时刻都没有持有任何证券，则code=None，price=cost=vol=0。
if count1 = 0 or count2 = 0 then
  signal sqlstate '45000' set message_text = 'securities_holding contains not data for the given time range.';
end if;

drop temporary table if exists transaction_holding_subtotal_tmp;
create temporary table transaction_holding_subtotal_tmp
  select
    tr.code,
    sum(tr.amount) amount
  from (
    select  -- 1st select clause: 期初市值
      code,
      - price * vol amount
    from securities_holding
    where time = start_time and code <> 'None'
      and code in (select code from securities_holding where time = end_time)
    union
    select  -- 2nd select clause: 期末市值
      code,
      price * vol amount
    from securities_holding
    where time = end_time and code <> 'None'
    union
    select  -- 3rd select clause: 期间交易金额
      code,
      sum(amount) amount
    from securities_transaction
    where time > start_time and time <= end_time
      and code in (select code from securities_holding where time = end_time)
      and (tname = '证券买入' or tname = '证券卖出' or tname = '红股入账')
    group by code
  ) tr
  group by tr.code;
select * from transaction_holding_subtotal_tmp;
end;
//
delimiter ;

-- transaction_holding_total
-- 浮盈（汇总）
drop procedure if exists transaction_holding_total;
delimiter //
create procedure transaction_holding_total (in start_time date, in end_time date)
begin
call transaction_holding_subtotal(start_time, end_time);
select sum(amount) from transaction_holding_subtotal_tmp;
end;
//
delimiter ;


-- investment_earning
-- 投资收益（给定时间区间）
drop procedure if exists investment_earning;
delimiter //
create procedure investment_earning (in start_time date, in end_time date)
begin

declare count_S0 int;
declare count_C0 int;
declare count_S1 int;
declare count_C1 int;

declare S0 decimal(20, 4);
declare C0 decimal(20, 4);
declare S1 decimal(20, 4);
declare C1 decimal(20, 4);
declare Cn decimal(20, 4);

select count(*) from securities_holding where time = start_time into count_S0;
select count(*) from cash_holding where time = start_time into count_C0;
select count(*) from securities_holding where time = end_time into count_S1;
select count(*) from cash_holding where time = end_time into count_C1;
if count_S0 = 0 or count_S1 = 0 then
  signal sqlstate '45000' set message_text = 'securities_holding contains not data for the given time range.';
end if;
if count_C0 = 0 or count_C1 = 0 then
  signal sqlstate '45000' set message_text = 'cash_holding contains not data for the given time range.';
end if;


select sum(price * vol) from securities_holding where time = start_time into S0;
select sum(price * vol) from securities_holding where time = end_time into S1;
select amount from cash_holding where time = start_time into C0;
select amount from cash_holding where time = end_time into C1;
select sum(amount) from securities_transaction where (tname='银行转存' or tname='银行转取') and time > start_time and time <= end_time into Cn;

select S0, C0, Cn, S1, C1, S1 + C1 - Cn - S0 - C0 earning;
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
       in per_l decimal(10,2), -- 市盈率下限，基于securities_day_quote中最新日期
       in per_u decimal(10,2), -- 市盈率上限，基于securities_day_quote中最新日期
       in pbr_l decimal(10,2), -- 市净率下限，基于securities_day_quote中最新日期
       in pbr_u decimal(10,2), -- 市净率上限，基于securities_day_quote中最新日期
       in roe_l decimal(10,2), -- 净资产收益率下限，基于securities_major_financial_kpi中最新日期
       in roe_u decimal(10,2), -- 净资产收益率上限，基于securities_major_financial_kpi中最新日期
       in row_limit int -- 返回满足条件的证券数量上限
       )
begin
declare quote_date date;
declare kpi_date date;
select max(time) from securities_day_quote into quote_date;
select max(time) from securities_major_financial_kpi where time like '%-12-31' into kpi_date;
drop temporary table if exists short_list_tmp;
create temporary table short_list_tmp
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
    and d.year = (div_inception_year + div_years - 1)
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

drop procedure if exists short_list_code;
delimiter //
create procedure short_list_code (
       in div_inception_year smallint, -- 分红起始年份
       in div_years tinyint, -- 分红年数
       in per_l decimal(10,2), -- 市盈率下限，基于securities_day_quote中最新日期
       in per_u decimal(10,2), -- 市盈率上限，基于securities_day_quote中最新日期
       in pbr_l decimal(10,2), -- 市净率下限，基于securities_day_quote中最新日期
       in pbr_u decimal(10,2), -- 市净率上限，基于securities_day_quote中最新日期
       in roe_l decimal(10,2), -- 净资产收益率下限，基于securities_major_financial_kpi中最新日期
       in roe_u decimal(10,2), -- 净资产收益率上限，基于securities_major_financial_kpi中最新日期
       in row_limit int -- 返回满足条件的证券数量上限
       )
begin
call short_list(div_inception_year, div_years, per_l, per_u, pbr_l, pbr_u, roe_l, roe_u, row_limit);
select 代码 code from short_list_tmp;
end;
//
delimiter ;

drop procedure if exists short_list_detail;
delimiter //
create procedure short_list_detail (
       in div_inception_year smallint, -- 分红起始年份
       in div_years tinyint, -- 分红年数
       in per_l decimal(10,2), -- 市盈率下限，基于securities_day_quote中最新日期
       in per_u decimal(10,2), -- 市盈率上限，基于securities_day_quote中最新日期
       in pbr_l decimal(10,2), -- 市净率下限，基于securities_day_quote中最新日期
       in pbr_u decimal(10,2), -- 市净率上限，基于securities_day_quote中最新日期
       in roe_l decimal(10,2), -- 净资产收益率下限，基于securities_major_financial_kpi中最新日期
       in roe_u decimal(10,2), -- 净资产收益率上限，基于securities_major_financial_kpi中最新日期
       in row_limit int -- 返回满足条件的证券数量上限
       )
begin
call short_list(div_inception_year, div_years, per_l, per_u, pbr_l, pbr_u, roe_l, roe_u, row_limit);
select * from short_list_tmp;
end;
//
delimiter ;

drop procedure if exists short_list_detail_default;
delimiter //
create procedure short_list_detail_default ()
begin
declare div_inception_year smallint;
declare div_years tinyint;
declare per_l decimal(10,2);
declare per_u decimal(10,2);
declare pbr_l decimal(10,2);
declare pbr_u decimal(10,2);
declare roe_l decimal(10,2);
declare roe_u decimal(10,2);
declare row_limit int;

set div_years = 5;
set div_inception_year = year(now()) - div_years;
set per_l = 0.01;
set per_u = 20;
set pbr_l = 0.01;
set pbr_u = 5;
set roe_l = 10;
set roe_u = 999;
set row_limit = 200;

call short_list(div_inception_year, div_years, per_l, per_u, pbr_l, pbr_u, roe_l, roe_u, row_limit);
select * from short_list_tmp;
select div_inception_year, div_years, per_l, per_u, pbr_l, pbr_u, roe_l, roe_u, row_limit;
end;
//
delimiter ;

-- data collection status
-- 汇总目前数据库中所收集数据的状态
-- 主要包括数据的时间
drop procedure if exists data_status;
delimiter //
create procedure data_status ()
begin
declare code_num int;
declare quote_date date;
declare div_year smallint;
declare kpi_date date;
declare sec_hold_date date;
declare cash_hold_date date;
declare trans_date date;

select count(*) from securities_code into code_num;
select max(time) from securities_day_quote into quote_date;
select max(year) from securities_dividend into div_year;
select max(time) from securities_major_financial_kpi into kpi_date;
select max(time) from securities_holding into sec_hold_date;
select max(time) from cash_holding into cash_hold_date;
select max(time) from securities_transaction into trans_date;

select
  code_num 证券数量,
  quote_date 行情日期,
  div_year 分红年度,
  kpi_date 指标年度,
  sec_hold_date 证券持有日期,
  cash_hold_date 现金持有日期,
  trans_date 交易日期;
end;
//
delimiter ;
