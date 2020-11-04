#!/usr/bin/env python
import pymarc
import glob
import datetime
import re
import traceback

def check_mfhd(record):
    if record.get_fields("245") or record.get_fields("240"):
        return False
    return True


def is_copy(callnum):

    m = re.search(r"c\.( *\d)", callnum)
    if m:
        return True
    return False

def check_multivolume(record):

    locations = {}
    if record.leader[19] == 'a':
        return True

    for field in record.get_fields("852"):
        if not full_holdings(field):
            continue

        call_num = field.get_subfields("j")[0]
        if is_copy(call_num):
            continue

        loc_name = "{}-{}".format(field.get_subfields("b")[0], field.get_subfields("c")[0])
        if loc_name not in locations:
            locations[loc_name] = []
        if call_num not in locations[loc_name]:
            locations[loc_name].append(call_num)

    for loc in locations:
        if len(locations[loc]) > 1:
            print("{}\t{}".format(record["001"].data, locations[loc]))
            return True

def full_holdings(field):
    if (
            field.get_subfields("b")
            and field.get_subfields("c")
            and field.get_subfields("j")
            and field.get_subfields("p")
            ):
        return True
    return False


def check_print(record):
    for field in record.get_fields("852"):
        if full_holdings(field):
            return True
    return False


def main():
    mrcs = glob.glob("laurentian.mrc")
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
                    if ctr % 10000 == 0:
                        print(ctr)
                    recid = record["001"].data
                    is_print = False
                    is_serial = False
                    is_multi = False
                    issns = []


                    is_mfhd = check_mfhd(record)
                    is_print = check_print(record)
                    if is_print is False or is_mfhd:
                        continue

                    is_multi = check_multivolume(record)
                    for field in record.get_fields("022"):
                        for sf in field.get_subfields("a"):
                            is_serial = True
                            issns.append(sf.strip())
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
                                elif is_multi:
                                    multif.write(
                                        "{}\t{}\t\t\t\t\t\n".format(oclcnum, recid)
                                    )
                                else:
                                    singlef.write(
                                        "{}\t{}\t\t\t\t\t\n".format(oclcnum, recid)
                                    )
            except Exception as e:
                traceback.print_exc()
                print("{} : {}".format(mrc, e))
                continue

if __name__ == '__main__':
    main()
