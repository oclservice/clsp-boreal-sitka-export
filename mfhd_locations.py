#!/usr/bin/env python
import pymarc
import glob
import datetime
import traceback

def update_locations(field):
    """Standardize sublocation (852 $b) and shelving (852 $c) text"""
    b_swaps = {
        "Centre Franco-Ontarien de Folklore": "CFOF",
        "Centre franco-ontarien de folklore": "CFOF",
        "Curriculum Resource Centre": "LDCR",
        "DESMAAIS": "OSUL",
        "DESMARAIAS": "OSUL",
        "DESMARAIS": "OSUL",
        "Desmarais": "OSUL",
        "J.N. Desmarais Library": "OSUL",
        "HUNTINGTON": "HUNTINGTON",
        "Huntington College Library": "HUNTINGTON",
        "Huntington University Library": "HUNTINGTON",
        "Laboratoire de didactiques, E.S.E.": "LDCR",
        "School of Architecture": "LAL",
        "SCHOOL OF ARCHITECTURE": "LAL",
        "Université de Sudbury": "SUDBURY",
        "University of Sudbury": "SUDBURY",
    }

    c_swaps = {
        "DEPOSITORY": "Depository",
        "DESM-ACH": "Archives",
        "DESM-ARCH": "Archives",
        "DESM-ARCHIVE": "Archives",
        "DESM-ARCHIVES/REF": "Archives (Reference)",
        "DESMAR-REF": "Archives (Reference)",
        "DESM-CIR": "Circulation",
        "DESM-CIR (backwall)": "Circulation",
        "DESM-CIR (shelved at the end of Z))": "Circulation",
        "DESM-DEP": "Depository",
        "DESM-DLI": "Government Documents",
        "DESM-DOC": "Government Documents",
        "DESM-DOCR": "Government Documents (Reference)",
        "DESM-DOCS": "Government Documents",
        "DESM-DOS": "Government Documents",
        "DESM-FAC": "Faculty Authors Collection",
        "DESM-FICHE": "Microfiche",
        "DESM-FIL": "Microfilm",
        "DESM-FILM": "Microfilm",
        "DESM-GOV": "Government Documents",
        "DESM-INFO": "Information Desk",
        "DESM-MICROFICHE": "Microfiche",
        "DESM-MRC": "Music Resource Centre",
        "DESM-PER": "Periodicals",
        "DESM-NEWS": "Newspapers",
        "DESM-REF": "Reference",
        "DESMI-DEP": "Depository",
        "DESMI-REF": "Reference",
        "DOC": "Government Documents",
        "MICROFICHE": "Microfiche",
        "RESERVES": "Reserves",
        "Archives.": "Archives",
        "Periodical": "Periodicals",
        "Periodical Room": "Periodicals",
        "PeriodicalS": "Periodicals",
        "Periodicals.": "Periodicals",
        "Périodique": "Periodicals",
        "Périodiques": "Periodicals",
        "Périodiques.": "Periodicals",
        "Périodiques/Periodicals": "Periodicals",
        "STACKS": "Circulation",
        "SUDB-PER": "Periodicals",

    }

    for i, txt in enumerate(field.subfields):
        if i and field.subfields[i - 1] == "b":
            if field.subfields[i] in b_swaps:
                field.subfields[i] = b_swaps[field.subfields[i]]
        if i and field.subfields[i - 1] == "c":
            if field.subfields[i] in c_swaps:
                field.subfields[i] = c_swaps[field.subfields[i]]


def main():

    mrcs = glob.glob("lumarc*")
    mrcs = glob.glob("laurentian.mrc")
    mrcs = glob.glob("OSUL_LU_mfhd_20200723.mrc")
    libraries = {}
    
    today = datetime.date.today().strftime("%Y%m%d")

    fields = ("770", "771", "772", "773", "774", "775", "776", "777", "780", "785", "787")
    ctr = 1

    with open("mfhd_locations_{}.lst".format(today), "w") as locf:
        for mrc in mrcs:
            try:
                marcf = pymarc.MARCReader(open(mrc, "rb"))
                for record in marcf:
                    ctr += 1
                    if ctr % 100 == 0:
                        print(ctr)
                    for field in record.get_fields("852"):
                        for sf in field.get_subfields("b"):
                            for sfc in field.get_subfields("c"):
                                key = "{}\t{}".format(sf, sfc)
                                libraries[key] = 1
            except Exception as e:
                traceback.print_exc()
                print("{} : {}".format(mrc, e))
                continue
        locf.write("= Libraries\n")
        for key in sorted(libraries):
            locf.write("{}\n".format(key))

if __name__ == '__main__':
    main()
