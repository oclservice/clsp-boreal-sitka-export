#!/usr/bin/env python
import pymarc
import glob
import datetime

mrcs = glob.glob("lumarc*")
today = datetime.date.today().strftime("%Y%m%d")

ctr = 1
with open("laurentian_single-part_{}.tsv".format(today), "w") as singlef, open(
    "laurentian_multi-part_{}.tsv".format(today), "w"
) as multif, open("laurentian_serials_{}.tsv".format(today), "w") as serialf:
    for mrc in mrcs:
        try:
            marcf = pymarc.MARCReader(open(mrc, "rb"))
            for record in marcf:
                ctr += 1
                if ctr % 100 == 0:
                    print(ctr)
                recid = record["001"].data
                is_print = False
                is_serial = False
                issns = []
                for field in record.get_fields("022"):
                    for sf in field.get_subfields("a"):
                        is_serial = True
                        issns.append(sf.strip())
                for field in record.get_fields("852"):
                    if (
                        field.get_subfields("b")
                        and field.get_subfields("c")
                        and field.get_subfields("j")
                        and field.get_subfields("p")
                    ):
                        is_print = True
                if is_print is False:
                    continue
                for field in record.get_fields("035"):
                    for sf in field.get_subfields("a"):
                        if sf.startswith("(OCoLC)"):
                            oclcnum = (
                                sf.replace("(OCoLC)", "")
                                .replace("ocm", "")
                                .replace("ocn", "")
                                .strip()
                            )
                            if is_serial:
                                serialf.write(
                                    "{}\t{}\t\t\t\t{}\t\n".format(
                                        oclcnum, recid, ",".join(issns)
                                    )
                                )
                            else:
                                singlef.write(
                                    "{}\t{}\t\t\t\t\t\n".format(oclcnum, recid)
                                )
        except Exception as e:
            print("{} : {}".format(mrc, e))
            continue
