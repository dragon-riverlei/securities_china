#!/usr/bin/python
# -*- coding: utf-8 -*-

import ConfigParser

import MySQLdb

import subprocess

import time

import re


class SecuritiesDB():
    db = None
    tdx_home = "/cygdrive/d/东莞证券/"
    date_rexp = re.compile(r"([0-9]{4})-([0-9]{2})-([0-9]{2})")

    def __init__(self):
        cfg = ConfigParser.ConfigParser()
        from os.path import expanduser
        home = expanduser("~")
        cfg.read(home + "/.my.cnf")
        (host, port, user, passwd) = (cfg.get("client", "host"), cfg.get(
            "client", "port"), cfg.get("client", "user"), cfg.get("client",
                                                                  "password"))
        self.db = MySQLdb.connect(host=host,
                                  port=int(port),
                                  user=user,
                                  passwd=passwd,
                                  db="securities",
                                  charset="utf8")

    def query_securities_code(self):
        self.db.query("select code, market, country from securities_code")
        return self.db.store_result()

    def query_securities_code_with_market(self):
        self.db.query("select code, market from securities_code")
        return self.db.store_result()

    def query_securities_code_for_dividend_plan(self, years):
        if(years is not None):
            sql = " union ".join(
                ["select code from securities_code where code not in "
                 "(select code from securities_dividend_plan where year=%s)" %
                 year for year in years])
        else:
            sql = "select code from securities_code"
        self.db.query(sql)
        return self.db.store_result()

    def query_short_list(self, start_year=time.localtime().tm_year-6,
                         num_years=5, per_l=0, per_u=1000,
                         pbr_l=0, pbr_u=1000,
                         roe_l=0, roe_u=1000,
                         row_limit=1000):
        cur = self.db.cursor()
        cur.callproc("short_list",
                     (start_year, num_years, per_l, per_u, pbr_l, pbr_u,
                      roe_l, roe_u, row_limit))
        return cur.fetchall()

    def insert_securities_code(self, codes):
        cur = self.db.cursor()
        for code in codes:
            cur.execute(
                "insert into securities_code "
                "values (%s, %s, %s) on duplicate key update code=%s",
                (code[0].strip(), code[1], code[2], code[0].strip()))
        self.db.commit()

    def insert_securities_dividend(self, dividends):
        cur = self.db.cursor()
        for div in dividends:
            cur.execute(
                "insert into securities_dividend "
                "values (%s, %s, %s, %s, %s, %s, %s, %s) "
                "on duplicate key update code=%s, year=%s, "
                "eps=%s, div1=%s, div2=%s, div3=%s, reg_time=%s, "
                "div_time=%s",
                (div[0], div[1], div[2], div[3], div[4], div[5],
                 div[6], div[7],
                 div[0], div[1], div[2], div[3], div[4], div[5],
                 div[6], div[7]))
        self.db.commit()

    def insert_securities_dividend_plan(self, dividends):
        cur = self.db.cursor()
        for div in dividends:
            cur.execute(
                "insert into securities_dividend_plan "
                "values (%s, %s, %s, %s, %s, %s) "
                "on duplicate key update code=%s, year=%s",
                (div[0], div[1], div[2], div[3], div[4], div[5],
                 div[0], div[1]))
        self.db.commit()

    def insert_securities_day_quote(self, quote):
        cur = self.db.cursor()
        cur.execute(
            "insert into securities_day_quote "
            "values (%s, %s, %s, %s, %s, %s, %s) "
            "on duplicate key update "
            "code=%s, time=%s, per=%s, pbr=%s, price=%s, amp=%s, vol=%s",
            (quote[0], quote[1], quote[2], quote[3], quote[4], quote[5],
             quote[6], quote[0], quote[1], quote[2], quote[3], quote[4],
             quote[5], quote[6]))
        self.db.commit()

    def insert_securities_day_quote_history(self, date, code):
        cmd = subprocess.Popen(['./TdxDayQuoteFile.sh', code],
                               stdout=subprocess.PIPE)
        out, err = cmd.communicate()
        day_quote_file = out.split('\n')[0]
        close_price = self.parse_tdx_day_quote_file(day_quote_file, date)
        # cur = self.db.cursor()
        # cur.execute(
        #     "insert into securities_day_quote_hisotry"
        #     "values (%s, %s, %s) "
        #     "on duplicate key update "
        #     "code=%s, time=%s, close_price=%s",
        #     (code, date, close_price))
        print (code, date, close_price)
        self.db.commit()

    def parse_tdx_day_quote_file(self, day_quote_file, date):
        m = self.date_rexp.match(date)
        if m is None:
            return None
        date = m.group(1) + m.group(2) + m.group(3)

        ifile = open(day_quote_file, 'rb')
        buf = ifile.read()
        ifile.close()

        no = len(buf)/32
        b = 0
        e = 32

        import struct
        for i in xrange(no):
            data = struct.unpack('IIIIIfII', buf[b:e])
            if(int(date) == data[0]):
                return str(data[4]/100.0)
            b += 32
            e += 32

    def insert_securities_major_financial_kpi(self, kpi):
        cur = self.db.cursor()
        kpi = kpi + [kpi[0]]
        cur.execute(
            "insert into securities_major_financial_kpi "
            "values (%s, %s, %s, %s, %s, %s, %s, %s, %s, "
            "%s, %s, %s, %s, %s, %s, %s, %s, %s) "
            "on duplicate key update code=%s", tuple(kpi))
        self.db.commit()

    def insert_securities_stock_structure(self, struc):
        cur = self.db.cursor()
        struc = struc + [struc[0], struc[1]]
        cur.execute(
            "insert into securities_stock_structure "
            "values (%s, %s, %s, %s, %s, %s, %s) "
            "on duplicate key update code=%s, time=%s", tuple(struc))
        self.db.commit()

    def insert_securities_transaction1(self):
        cmd = subprocess.Popen('./SecuritiesTransactions1.sh',
                               stdout=subprocess.PIPE)
        out, err = cmd.communicate()
        transactions = out.split('\n')
        cur = self.db.cursor()
        for tran in transactions:
            if (len(tran.split()) == 7):
                t = tran.split()
                cur.execute(
                    "insert into securities_transaction "
                    "(time, code, price, vol, tname, amount, balance) "
                    "values (%s, %s, %s, %s, %s, %s, %s)",
                    (t[0], t[1], t[2], t[3], t[4], t[5], t[6]))
        self.db.commit()

    def insert_securities_transaction2(self):
        cmd = subprocess.Popen('./SecuritiesTransactions2.sh',
                               stdout=subprocess.PIPE)
        out, err = cmd.communicate()
        transactions = out.split('\n')
        cur = self.db.cursor()
        for tran in transactions:
            if (len(tran.split()) == 4):
                t = tran.split()
                cur.execute(
                    "insert into securities_transaction "
                    "(time, code, price, vol, tname, amount, balance) "
                    "values (%s, %s, %s, %s, %s, %s, %s)",
                    (t[0], "", 0.0, 0.0, t[1], t[2], t[3]))
        self.db.commit()

    def insert_securities_holdings(self, date):
        cmd = subprocess.Popen('./SecuritiesHoldings.sh',
                               stdout=subprocess.PIPE)
        out, err = cmd.communicate()
        holdings = out.split('\n')
        cur = self.db.cursor()
        for holding in holdings:
            if (len(holding.split()) == 4):
                h = holding.split()
                cur.execute(
                    "insert into securities_holding "
                    "(time, code, price, cost, vol) "
                    "values (%s, %s, %s, %s, %s)",
                    (date, h[0], h[3], h[2], h[1]))
        self.db.commit()

    def insert_fund_code(self, code):
        cur = self.db.cursor()
        cur.execute(
            "insert into fund_code "
            "(code, name, type) "
            "values (%s, %s, %s) "
            "on duplicate key update", code)
        self.db.commit()


if __name__ == "__main__":
    sdb = SecuritiesDB()
    sdb.insert_securities_transaction1()
    sdb.insert_securities_transaction2()
