# -*- coding: utf-8 -*-
#
# 上海，深圳证券分红
# http://stock.finance.qq.com/corp1/distri.php?zqdm=${code}

import scrapy

from securities_china.SecuritiesDB import SecuritiesDB


class SecuritiesDividend(scrapy.Spider):
    db = SecuritiesDB()

    name = "SecuritiesDividend"
    allowed_domains = ["stock.finance.qq.com"]
    url_tpl = "http://stock.finance.qq.com/corp1/distri.php?zqdm="
    start_urls = [
        url_tpl + code[0] for code in db.query_securities_code().fetch_row(0)
    ]

    def parse(self, response):
        self.db.insert_securities_dividend(self.merge_rows(response))

    def merge_rows(self, response):
        import itertools
        import operator
        from decimal import getcontext, Decimal
        getcontext().prec = 4

        it = itertools.groupby(
            self.parse_rows(response), operator.itemgetter(1))
        for key, subiter in it:
            eps = div1 = div2 = div3 = Decimal(0)
            code = year = eps = reg_time = div_time = ""
            for item in subiter:
                div1 = div1 + Decimal(item[3])
                div2 = div2 + Decimal(item[4])
                div3 = div3 + Decimal(item[5])
                code = item[0]
                year = item[1]
                eps = Decimal(item[2])
                reg_time = item[6]
                div_time = item[7]
            yield (code, year, str(eps), str(div1), str(div2), str(div3),
                   reg_time, div_time)

    def parse_rows(self, response):
        code = response.url.split("zqdm=")[1]
        rows = response.xpath("/html/body/div/div/table[3]/tr")
        for i in range(2, len(rows)):
            values = rows[i].xpath("td/text()").extract()
            year = values[0][:4]
            eps = values[1] if values[1] != "--" else "0.0"
            div1 = values[2] if values[2] != "--" else "0"
            div2 = values[3] if values[3] != "--" else "0"
            div3 = values[4] if values[4] != "--" else "0.0"
            reg_time = values[5] if values[5] != "--" else "1970-01-01"
            div_time = values[6] if values[6] != "--" else "1970-01-01"
            yield (code, year, eps, div1, div2, div3, reg_time, div_time)
