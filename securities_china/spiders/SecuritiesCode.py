# -*- coding: utf-8 -*-
#
# 上海，深圳证券代码

# 上海
# http://stock.gtimg.cn/data/get_hs_xls.php?id=rankash&type=1&metric=chr
# 深圳
# http://stock.gtimg.cn/data/get_hs_xls.php?id=rankasz&type=1&metric=chr

import scrapy
from xlrd import open_workbook
from securities_china.SecuritiesDB import SecuritiesDB


class SecuritiesCode(scrapy.Spider):
    name = "SecuritiesCode"
    allowed_domains = ["stock.gtimg.cn"]
    start_urls = [
        "http://stock.gtimg.cn/data/get_hs_xls.php?"
        "id=rankash&type=1&metric=chr",
        "http://stock.gtimg.cn/data/get_hs_xls.php?"
        "id=rankasz&type=1&metric=chr"
    ]

    def __init__(self):
        self.db = SecuritiesDB()

    def parse(self, response):
        sheet = open_workbook(file_contents=response.body).sheets()[0]
        codes = set()
        market = "Shanghai" if response.url == self.start_urls[
            0] else "Shenzhen"
        country = "China"
        for row in range(sheet.nrows):
            code = sheet.cell(row, 0).value[2:]
            if code.isdigit():
                codes.add((code, market, country))
        self.db.insert_securities_code(codes)
