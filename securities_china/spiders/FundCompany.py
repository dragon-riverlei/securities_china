# -*- coding: utf-8 -*-
#
# 基金公司

import scrapy
import logging

from securities_china.SecuritiesDB import SecuritiesDB

logger = logging.getLogger(__name__)


class FundCompany(scrapy.Spider):
    name = "FundCompany"
    allowed_domains = ["www.howbuy.com"]

    def __init__(self):
        self.db = SecuritiesDB()
        self.start_urls = [
          "http://www.howbuy.com/fund/company/"
        ]

    def parse(self, response):
        rows = response.css("#company-chart").xpath("tbody/td")
        for row in self.company_chunk(rows):
            id = row[1].xpath("a/@href").extract()[0][14:22]
            name = row[1].xpath("a/text()").extract()[0]
            asset = row[2].xpath("text()").extract()[0]
            time = row[3].xpath("text()").extract()[0]
            try:
                if float(asset) >= 300.0:
                    self.db.insert_fund_company((id, name, time, asset))
            except ValueError:
                continue

    def company_chunk(self, rows):
        for i in range(0, len(rows), 10):
            yield rows[i:i+10]
