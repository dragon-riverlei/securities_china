# -*- coding: utf-8 -*-
#
# 上海，深圳证券股本结构
# http://stock.finance.qq.com/corp1/stk_struct.php?zqdm=${code}


import scrapy
import re
import unicodedata

from securities_china.SecuritiesDB import SecuritiesDB

class SecuritiesStockStructure (scrapy.Spider):
    db = SecuritiesDB()
        
    name = "SecuritiesStockStructure"
    allowed_domains = ["stock.finance.qq.com"]
    url_tpl = "http://stock.finance.qq.com/corp1/stk_struct.php?zqdm="
    start_urls = [
        url_tpl + code[0] for code in db.query_short_list_01().fetch_row(maxrows=0)
    ]
    time_rexp = re.compile(r"[0-9]{4}-[0-9]{2}-[0-9]{2}")
    parts = [
        ("变更原因", 3),
        ("总股本", 5),
        ("流通股份", 6),
        ("流通A股", 7),
        ("流通H股", 9)
    ]
    
    def parse(self, response):
        self.parseStockStructure(response)
        
        links = response.xpath("/html/body/div[2]/div[1]/table[2]/tr/td/a/@href").extract()
        links = links + response.xpath("/html/body/div[2]/div[1]/table[2]/td/a/@href").extract()
        for link in links:
            yield scrapy.Request(link, self.parse2)
        
    def parse2(self, response):
        self.parseStockStructure(response)

    def parseStockStructure(self, response):
        code = response.url.split("zqdm=")[1].split("&type=")[0].strip()
        trs = response.xpath("/html/body/div[2]/div[1]/table[3]/tr")
        times = [ time for time in trs[0].xpath("td/text()").extract() if self.time_rexp.match(time) != None]
        for i in range(len(times)):
            values = [ value for value in
                       [ trs[part[1]-1].xpath("td[" + str(i+1) + "]/text()").extract()[0] for part in self.parts ]
            ]
            values = [ value.replace(",", "") for value in values ]
            values = [ unicodedata.normalize("NFKD",value) for value in values ]
            values = [ values[j] if j< 3 else values[j].replace(" ", "0.00") for j in range(len(values)) ]
            values = [code, times[i]] + values
            
            self.db.insert_securities_stock_structure(values)
