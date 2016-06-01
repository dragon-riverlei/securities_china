#!/usr/bin/python
# -*- coding: utf-8 -*-

import MySQLdb
import ConfigParser
import re

class SecuritiesDB():
    db = None
    
    def __init__(self):
        cfg = ConfigParser.ConfigParser()
        from os.path import expanduser
        home = expanduser("~")
        cfg.read(home+"/.my.cnf")
        (host, port, user, passwd) = (cfg.get("client", "host"), cfg.get("client", "port"), cfg.get("client", "user"), cfg.get("client", "password"))
        self.db = MySQLdb.connect(host=host, port=int(port), user=user, passwd=passwd, db="securities",charset="utf8")

    def query_securities_code(self):
        self.db.query("select * from securities_code")
        return self.db.store_result()

    def query_securities_code_with_market(self):
        self.db.query("select code, market from securities_code")
        return self.db.store_result()

    def query_dividend_prone_securities(self):
        self.db.query("select code,market from dividend_2010_5")
        return self.db.store_result()

    def query_short_list_01(self):
        self.db.query("select code from short_list_01")
        return self.db.store_result()
        
    def insert_securities_code(self, codes):
        cur = self.db.cursor()
        for code in codes:
            cur.execute("insert into securities_code  values (%s, %s, %s) on duplicate key update code=%s", (code[0].strip(), code[1], code[2], code[0].strip()))
        self.db.commit()

    def insert_securities_dividend(self, dividends):
        cur = self.db.cursor()
        for div in dividends:
            cur.execute("insert into securities_dividend values (%s, %s, %s, %s, %s, %s, %s, %s) on duplicate key update code=%s, year=%s",
                        (div[0], div[1], div[2], div[3], div[4], div[5], div[6], div[7], div[0], div[1]))
        self.db.commit()

    def insert_securities_dividend_plan(self, dividends):
        cur = self.db.cursor()
        for div in dividends:
            cur.execute("insert into securities_dividend_plan values (%s, %s, %s, %s, %s, %s) on duplicate key update code=%s, year=%s",
                        (div[0], div[1], div[2], div[3], div[4], div[5], div[0], div[1]))
        self.db.commit()        

    def insert_securities_day_quote(self, quote):
        cur = self.db.cursor()
        cur.execute("insert into securities_day_quote values (%s, %s, %s, %s, %s, %s, %s) on duplicate key update code=%s, time=%s, per=%s, pbr=%s, price=%s, amp=%s, vol=%s",
                    (quote[0], quote[1], quote[2], quote[3], quote[4], quote[5], quote[6], quote[0], quote[1], quote[2], quote[3], quote[4], quote[5], quote[6]))
        self.db.commit()

    def insert_securities_major_financial_kpi(self, kpi):
        cur = self.db.cursor()
        kpi = kpi + [kpi[0]]
        cur.execute("insert into securities_major_financial_kpi values (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s) on duplicate key update code=%s", tuple(kpi))
        self.db.commit()

    def insert_securities_stock_structure(self, struc):
        cur = self.db.cursor()
        struc = struc + [struc[0], struc[1]]
        cur.execute("insert into securities_stock_structure values (%s, %s, %s, %s, %s, %s, %s) on duplicate key update code=%s, time=%s", tuple(struc))
        self.db.commit()
        
if __name__ == "__main__":
    sdb = SecuritiesDB()

        
