# -*- coding: utf-8 -*-
#
# 上海，深圳证券分红计划
# http://stock.finance.qq.com/corp1/distri.php?zqdm=${code}

import scrapy

from securities_china.SecuritiesDB import SecuritiesDB


class SecuritiesDividendPlan(scrapy.Spider):
    db = SecuritiesDB()

    name = "SecuritiesDividendPlan"
    allowed_domains = ["stock.finance.qq.com"]
    url_tpl = "http://stock.finance.qq.com/corp1/distri.php?zqdm="

    # start_urls = [
    #     url_tpl + code[0] for code in db.query_securities_code().fetch_row(0)
    # ]

    def __init__(self, years=None, codes=None):
        if (years is not None):
            self.years = years.split(",")
        else:
            self.years = None

        if (codes is not None):
            self.codes = codes.split(",")
        else:
            self.codes = None

        if (self.codes is not None):
            self.start_urls = [self.url_tpl + code for code in self.codes]
        else:
            self.start_urls = [
                self.url_tpl + code[0]
                for code in
                self.db.query_securities_code_without_dividend_plan(self.years)
                .fetch_row(maxrows=0)
            ]

    def parse(self, response):
        self.db.insert_securities_dividend_plan(self.merge_rows(response))

    def merge_rows(self, response):
        import itertools
        import operator
        from decimal import getcontext, Decimal
        getcontext().prec = 4

        it = itertools.groupby(
            self.parse_rows(response), operator.itemgetter(1))
        for key, subiter in it:
            eps = div1 = div2 = div3 = Decimal(0)
            code = year = eps = ""
            for item in subiter:
                div1 = div1 + Decimal(item[3])
                div2 = div2 + Decimal(item[4])
                div3 = div3 + Decimal(item[5])
                code = item[0]
                year = item[1]
                eps = Decimal(item[2])
            yield (code, year, str(eps), str(div1), str(div2), str(div3))

    def parse_rows(self, response):
        code = response.url.split("zqdm=")[1]
        rows = response.xpath("/html/body/div/div/table[2]/tr")
        for i in range(2, len(rows)):
            values = rows[i].xpath("td/text()").extract()
            year = values[0][:4]
            eps = values[1] if values[1] != "--" else "0.0"
            div1 = values[2] if values[2] != "--" else "0"
            div2 = values[3] if values[3] != "--" else "0"
            div3 = values[4] if values[4] != "--" else "0.0"
            if (self.years is None or year in self.years):
                yield (code, year, eps, div1, div2, div3)
