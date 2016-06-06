# -*- coding: utf-8 -*-
#
# 上海，深圳证券主要财务指标
# http://stock.finance.qq.com/corp1/mfratio.php?zqdm=${code}

from __future__ import print_function
import scrapy
import re

from securities_china.SecuritiesDB import SecuritiesDB


class SecuritiesMajorFinancialKPI (scrapy.Spider):
    db = SecuritiesDB()

    name = "SecuritiesMajorFinancialKPI"
    allowed_domains = ["stock.finance.qq.com"]
    url_tpl = "http://stock.finance.qq.com/corp1/mfratio.php?zqdm="
    start_urls = [
        url_tpl + code[0]
        for code in db.query_securities_code().fetch_row(maxrows=0)
    ]
    time_rexp = re.compile(r"[0-9]{4}-[0-9]{2}-[0-9]{2}")
    unit_rexp = re.compile(r"[^0-9,.]*$")
    kpis = [
        ("基本每股收益", "MFRation28", 2),
        ("每股净资产", "MFRation18", 7),
        ("每股经营活动产生的现金流量净额", "MFRation20", 9),
        ("净资产收益率加权", "MFRation22", 11),
        ("主营业务收入", "MFRation10", 12),
        ("主营业务利润", "MFRation4", 13),
        ("营业利润", "MFRation5", 14),
        ("投资收益", "MFRation6", 15),
        ("营业外收支净额", "MFRation7", 16),
        ("利润总额", "MFRation1", 17),
        ("净利润", "MFRation2", 18),
        ("净利润(扣除非经常性损益后)", "MFRation3", 19),
        ("经营活动产生的现金流量净额", "MFRation8", 20),
        ("现金及现金等价物净增加额", "MFRation9", 21),
        ("总资产", "MFRation12", 24),
        ("股东权益不含少数股东权益", "MFRation13", 25)
    ]

    def __init__(self, dates=None):
        if(dates is not None):
            self.dates = dates.split(",")
            self.years = {
                date[:4] for date in self.dates
                if self.time_rexp.match(date) is not None
            }
        else:
            self.dates = None
            self.years = None

    def parse(self, response):
        links = response.xpath(
            "/html/body/div[2]/div/table[2]/tr[1]/td/a/@href").extract()
        if(self.years is not None):
            links = [
                link for link in links
                if link.split("type=")[1] in self.years
            ]
        for link in links:
            yield scrapy.Request(link, self.eachYear)

    def eachYear(self, response):
        code = response.url.split("zqdm=")[1].split("&type=")[0].strip()
        trs = response.xpath("/html/body/div[2]/div/table[3]/tr")
        times = [
            time for time in trs[0].xpath("td/text()").extract()
            if self.time_rexp.match(time) is not None]
        chosenTimes = list(times)
        if(self.dates is not None):
            chosenTimes = [
                time for time in chosenTimes
                if time in self.dates
            ]
        for time in chosenTimes:
            i = times.index(time)
            values = [
                re.sub(self.unit_rexp, "", value)
                for value in [
                       trs[kpi[2]-1].xpath(
                           "td[ " + str(i+1) + "]/text()").extract()[0]
                       for kpi in self.kpis
                ]
            ]
            values = [value if value != "" else "0.0000" for value in values]
            values = [value.replace(",", "") for value in values]
            values = [code, times[i]] + values
            self.db.insert_securities_major_financial_kpi(values)

    def kpiNames(self, response):
        """Print all the kpi names found in the url to
           the file named after the securities code.
           This is to help verify if all the securties
           share the same set of kpis.
        """
        code = response.url.split("zqdm=")[1].split("&type=")[0].strip()
        f = open(code, "w")
        for kpi in response.xpath(
                "/html/body/div[2]/div/table[3]/tr/th/a/text()").extract():
            print(kpi.encode("UTF-8"), file=f)
        f.close()
