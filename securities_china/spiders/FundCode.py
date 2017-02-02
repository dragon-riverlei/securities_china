# -*- coding: utf-8 -*-
#
# 基金代码

import scrapy
import json
import logging

from securities_china.SecuritiesDB import SecuritiesDB

logger = logging.getLogger(__name__)


class FundCode(scrapy.Spider):
    name = "FundCode"
    allowed_domains = ["www.howbuy.com"]
    url = "http://www.howbuy.com/fund/ajax/fundtool/newfilter.htm"
    fund_types = {'1': 1, '3': 2,
                  '9': 3, '8': 4,
                  '5': 5, '7': 6,
                  '53': 7, 'b': 8}

    def __init__(self):
        self.db = SecuritiesDB()

    def start_requests(self):
        requests = [
            scrapy.FormRequest(self.url,
                               formdata={
                                   "fundTypeCode": ft,
                                   "tradeStatus": "gm"})
            for ft in self.fund_types.keys()
        ]
        for req in requests:
            yield req

    def parse(self, response):
        page_info = json.loads(
            response.css(
                "label[id='viewJson']").xpath("text()").extract()[0])
        page_info = page_info["page"]
        next_page = str(page_info["page"] + 1)
        start = page_info["startRs"]
        total = page_info["total"]
        raw_type = [data.split("=")[1]
                    for data in response.request.body.split("&")
                    if data.startswith("fundTypeCode")][0]
        fund_type = self.fund_types[raw_type]
        current = len(response.css("table").xpath("tbody/tr/td/input"))
        current += int(start)
        for fund in response.css("table").xpath("tbody/tr/td/input"):
            code = fund.xpath("@jjdm").extract()[0]
            name = fund.xpath("@jjjc").extract()[0]
            f = (code, name, fund_type)
            logger.info("Fund code: " + str(f))
            self.db.insert_fund_code(f)
        if current < int(total):
            yield scrapy.FormRequest(
                self.url,
                formdata={
                    "fundTypeCode": raw_type,
                    "tradeStatus": "gm",
                    "page": next_page})
