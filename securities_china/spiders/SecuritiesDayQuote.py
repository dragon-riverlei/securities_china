# -*- coding: utf-8 -*-
#
# 上海证券当日行情
# http://qt.gtimg.cn/q=sh${code},
#
# 深圳证券当日行情
# http://qt.gtimg.cn/q=sz${code},

import scrapy

import logging

import time

from securities_china.SecuritiesDB import SecuritiesDB
from datetime import date

logger = logging.getLogger(__name__)


class SecuritiesDayQuote(scrapy.Spider):
    db = SecuritiesDB()

    name = "SecuritiesDayQuote"
    allowed_domains = ["qt.gtimg.cn"]
    url_tpl = "http://qt.gtimg.cn/q="

    def __init__(self):
        self.start_urls = [
            self.url_tpl + "sh" + code[0]
            if code[1] == "Shanghai" else self.url_tpl + "sz" + code[0]
            for code in
            self.db.query_securities_code_with_market().fetch_row(maxrows=0)
        ]
        logger.info("scrape securities day quote of " +
                    time.strftime("%Y-%m-%d", time.localtime()))

    def parse(self, response):
        values = response.body.split("~")
        (code, per, pbr, price, amp, vol) = (values[2], values[39], values[46],
                                             values[3], values[43], values[6])
        record = (code, date.today().isoformat(), per, pbr, price, amp, vol)
        logger.info("day quote: " + str(record))
        self.db.insert_securities_day_quote(record)
