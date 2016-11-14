# -*- coding: utf-8 -*-
#
# 基金代码

import scrapy

import logging

from securities_china.SecuritiesDB import SecuritiesDB

logger = logging.getLogger(__name__)


class FundCode(scrapy.Spider):
    name = "FundCode"
    allowed_domains = ["www.howbuy.com"]
    url_tpl = "http://www.howbuy.com/fund/ajax/fundtool/newfilter.htm?"\
              "fundType=%s&page="
    # fund_types = {'1': 1, '3': 2,
    #               '9': 3, '8': 4,
    #               '5': 5, '7': 6,
    #               '53': 7, 'b': 8}
    fund_types = {'1': 1}

    def __init__(self):
        self.start_urls = [
            self.url_tpl % ft + "1" for ft in self.fund_types.keys()]

    def parse(self, response):
        currentPage = response.xpath(
            "//div[@class='filter_result_list']/"
            "div[@class='bottom']/div[@class='pages']/"
            "span[@class='currentPage']/text()")[0].extract()
        countPage = response.xpath(
            "//div[@class='filter_result_list']/"
            "div[@class='bottom']/div[@class='pages']/"
            "span[@class='countPage']/text()")[0].extract()
        response.xpath("//div[@class='filter_result_list']/"
                       "div[@class='result_list_table']/"
                       "table/tbody/tr/td/input")
        if int(currentPage) < int(countPage):
            yield scrapy.Request(
                response.url.split("&")[0] + "&page=" + (int(currentPage) + 1),
                self.parse)
        pass
