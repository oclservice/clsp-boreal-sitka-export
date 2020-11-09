#!/usr/bin/env python
import pymarc
import glob
import datetime
import re
import traceback


def update_locations(field):
    """Standardize sublocation (852 $b) and shelving (852 $c) text"""
    b_swaps = {
        "ARCHITECTURE": "LAL",
        "Centre Franco-Ontarien de Folklore": "CFOF",
        "Centre franco-ontarien de folklore": "CFOF",
        "crc circ": "LDCR",
        "crc pic": "LDCR",
        "crc vidd": "LDCR",
        "Curriculum Resource Centre": "LDCR",
        "DESM-DEP": "OSUL",
        "DESM-PER": "OSUL",
        "DESMAAIS": "OSUL",
        "DESMARAIAS": "OSUL",
        "DESMARAIS": "OSUL",
        "DESMARAIS-DEP": "OSUL",
        "DESMARASI": "OSUL",
        "DESMRAIS": "OSUL",
        "Desmarais": "OSUL",
        "Instructional Media Centre": "ITServiceDesk",
        "J.N. Desmarais Library": "OSUL",
        "HUNTINGTON": "HUNTINGTON",
        "Huntington College Library": "HUNTINGTON",
        "Huntington University Library": "HUNTINGTON",
        "Huntington University Library - BV 4401 A1 J68": "HUNTINGTON",
        "Huntington University Library - Storage": "HUNTINGTON",
        "Huntington University Library - Storage ": "HUNTINGTON",
        "Laboratoire de didactiques, E.S.E.": "LDCR",
        "Laurentian University": "OSUL",
        "Leddy Library": "OWA",
        "led ser": "OWA",
        "ledl circ": "OWA",
        "ledl disn": "OWA",
        "ledl dnon": "OWA",
        "ledl docs": "OWA",
        "ledl mfms": "OWA",
        "ledl ref": "OWA",
        "ledl ser": "OWA",
        "ledl vidd": "OWA",
        "leld ser": "OWA",
        "School of Architecture": "LAL",
        "SCHOOL OF ARCHITECTURE": "LAL",
        "Périodiques": "SUDBURY",
        "Université de Sudbury": "SUDBURY",
        "University of Sudbury": "SUDBURY",
        "Université Laurentienne - Laurentian University": "OSUL",
    }

    c_swaps = {
        "DEPOSITORY": "Depository",
        "DESM-ACH": "Archives",
        "DESM-ARCH": "Archives",
        "DESM-ARCHIVE": "Archives",
        "DESM-ARCHIVES/REF": "Archives (Reference)",
        "DESMAR-REF": "Archives (Reference)",
        "Circulation (3rd floor)": "Circulation",
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
        "DESM=PER": "Periodicals",
        "DESM-NEWS": "Newspapers",
        "DESM-REF": "Reference",
        "REFERENCE": "Reference",
        "DEPOSITORY (1st Floor)": "Depository",
        "DESMI-DEP": "Depository",
        "DESMI-REF": "Reference",
        "DESM-BIBL": "Bibliographies",
        "AV": "Audio-visual",
        "DESM-CD": "Audio-visual",
        "Videos": "Audio-visual",
        "DESM-CIRC (shelved at the end of Z)": "Circulation",
        "DESM-DEP ": "Depository",
        "DESM-FAC ": "Faculty Authors Collection",
        "DESM-IND": "Indexes",
        "DESM-PER ": "Periodicals",
        "DESM-PERIODICAL": "Periodicals",
        "DESM-RARE": "Archives (Rare Books Collection)",
        "DESM-REF                              ": "Reference",
        "DESM-REF (Back Wall)": "Reference (Back Wall)",
        "DESM-REF/DEP": "Depository (Reference)",
        "DESM-REG": "Reference",
        "DOC": "Government Documents",
        "HUNT PER": "Periodicals",
        "HUNT-PER": "Periodicals",
        "HUNT-STPER": "Periodicals (Storage)",
        "In storage.": "Periodicals (Storage)",
        "LAL-PER": "Periodicals",
        "School of Architecture": "Periodicals",
        "MICROFICHE": "Microfiche",
        "RESERVES": "Reserves",
        "Archives.": "Archives",
        "PERIODICAL": "Periodicals",
        "Periodical": "Periodicals",
        "Periodical Room": "Periodicals",
        "PeriodicalS": "Periodicals",
        "Periodicals.": "Periodicals",
        "Periodiques": "Periodicals",
        "Périodique": "Periodicals",
        "Périodiques": "Periodicals",
        "Périodiques.": "Periodicals",
        "Périodiques/Periodicals": "Periodicals",
        "STACKS": "Circulation",
        "Stacks": "Circulation",
        "SUDB-PER": "Periodicals",
        "livre rare - rare book collection": "Rare Books Collection",
        "Rare": "Rare Books Collection",
        "DESM-WWW": "Online",
        "FILESERVER": "Online",
        "Internet": "Online",
        "Periodicals - online": "Online",
    }

    for i, txt in enumerate(field.subfields):
        if i and field.subfields[i - 1] == "b":
            if field.subfields[i] in b_swaps:
                field.subfields[i] = b_swaps[field.subfields[i]]
        if i and field.subfields[i - 1] == "c":
            if field.subfields[i] in c_swaps:
                field.subfields[i] = c_swaps[field.subfields[i]]


def split_provider(field):
    """
    Break the electronic provider out into a separate subfield

    From 856 $y Available online / Disponible en ligne (ScholarsPortal)
    To   856 $y Available online / Disponible en ligne $e ScholarsPortal
    """

    avail = "Available online / disponible en ligne"
    for i, txt in enumerate(field.subfields):
        if i and field.subfields[i - 1] == "y":
            m = re.search(r"^.*?\((.*?)\)", field.subfields[i])
            if m:
                field.subfields[i] = avail
                field.add_subfield("e", m.group(1))
            elif (
                "Available" in txt
                or "Avaialable" in txt
                or "Avaiilable online" in txt
                or "AVailable" in txt
                or "Availabe" in txt
                or "Availalbe" in txt
                or "Availble" in txt
                or "Check" in txt
                or "Click" in txt
                or "Connect to resource" in txt
                or "Disponibl" in txt
                or "Disponigle" in txt
                or "Disponilbe" in txt
                or "Online version here" in txt
                or "PDF version available" in txt
                or "Scholars Portal Books" in txt
                or "Taylor & Francis eBooks A-Z" in txt
            ):
                field.subfields[i] = avail


def remove_other_856(record, field):
    "Discard 856 fields from other universities"

    for u in field.get_subfields("u"):
        if "libproxy.auc.ca" in u or "ezproxy.uwindsor.ca" in u:
            record.remove_field(field)
            return

    for nine in field.get_subfields("9"):
        if (
            "ALGOMASYS" in nine
            or "HRSRH" in nine
            or "HSN" in nine
            or "NBRHC" in nine
            or "OSM" in nine
            or "SAH" in nine
        ):
            record.remove_field(field)

    for z in field.get_subfields("z"):
        if "Windsor's electronic resource" in z:
            record.remove_field(field)


def update_lu_proxy(field):
    "Move to a secure proxy prefix for legacy records"
    old_proxy = "http://librweb.laurentian.ca"
    https_proxy = "https://login.librweb.laurentian.ca"

    for i, txt in enumerate(field.subfields):
        if i and field.subfields[i - 1] == "u" and old_proxy in txt:
            field.subfields[i] = txt.replace(old_proxy, https_proxy)


def deoclcnum_french_records(record):
    "Prevent our French records from matching English records in the NZ"
    for f in record.get_fields("041"):
        for i, lang in enumerate(f.subfields):
            if i and f.subfields[i - 1] == "a":
                if "fre" in lang:
                    for r in record.get_fields("035"):
                        for idnum in r.get_subfields("a"):
                            if "OCoLC" in idnum:
                                record.remove_field(r)
                # Use multiple $a to conform to 041 requirements
                if lang == "engfre":
                    f.subfields[i] = "eng"
                    f.add_subfield("a", "fre")


def munge_mfhd(record):
    """
    Create MFHD records that make Alma happier

    Alma allows you to specify one MFHD field for summary holdings. We use 866.

    But we also use 867 for supplementary materials, 900 for internal notes,
    590 for missing materials, and 591 to indicate incomplete materials. We'll
    have to translate them all into multiple 866s with different subfields,
    e.g.:

    866    $a (1988) - (1999)
    867  0 $a Table of contents: 1988, 1989-1992, 1993-1999
    900    $a Cancelled Oct.19/99; CANCELLATION EFFECTIVE AS PER EXPIRY DATE (Dec. 1999)
    591    $a 1990-1992

    becomes:

    866    $a (1988) - (1999)
    866    $a Supplemental: Table of contents: 1988, 1989-1992, 1993-1999
    866    $y Cancelled Oct.19/99; CANCELLATION EFFECTIVE AS PER EXPIRY DATE (Dec. 1999)
    866    $z Incomplete: 1990-1992
    """

    for f in record.get_fields("867"):
        for a in f.get_subfields("a"):
            nf = pymarc.field.Field(
                tag="866",
                indicators=[" ", " "],
                subfields=["a", "Supplemental: {}".format(a)],
            )
            record.add_ordered_field(nf)
        record.remove_field(f)

    for f in record.get_fields("868"):
        for a in f.get_subfields("a"):
            nf = pymarc.field.Field(
                tag="866",
                indicators=[" ", " "],
                subfields=["a", "Indexes: {}".format(a)],
            )
            record.add_ordered_field(nf)
        record.remove_field(f)

    for f in record.get_fields("590"):
        for a in f.get_subfields("a"):
            nf = pymarc.field.Field(
                tag="866",
                indicators=[" ", " "],
                subfields=["z", "Missing: {}".format(a)],
            )
            record.add_ordered_field(nf)
        record.remove_field(f)

    for f in record.get_fields("591"):
        for a in f.get_subfields("a"):
            nf = pymarc.field.Field(
                tag="866",
                indicators=[" ", " "],
                subfields=["z", "Incomplete: {}".format(a)],
            )
            record.add_ordered_field(nf)
        record.remove_field(f)

    for f in record.get_fields("900"):
        for a in f.get_subfields("a"):
            nf = pymarc.field.Field(
                tag="866", indicators=[" ", " "], subfields=["y", a]
            )
            record.add_ordered_field(nf)
        record.remove_field(f)


def main():

    mrcs = glob.glob("lumarc*")
    mrcs = glob.glob("laurentian.mrc")
    # mrcs = glob.glob("laurentian_test.mrc")
    today = datetime.date.today().strftime("%Y%m%d")
    local_fields = (
        "770",
        "771",
        "772",
        "773",
        "774",
        "775",
        "776",
        "777",
        "780",
        "785",
        "787",
    )
    ctr = 1
    url_notes = {}

    with open("OCUL_LU_bib_{}.mrc".format(today), "wb") as localf, open(
        "OCUL_LU_mfhd_{}.mrc".format(today), "wb"
    ) as mfhdf:
        for mrc in mrcs:
            try:
                marcf = pymarc.MARCReader(open(mrc, "rb"))
                for record in marcf:
                    ctr += 1
                    if ctr % 1000 == 0:
                        print(ctr)
                    deoclcnum_french_records(record)
                    for field in record.get_fields(*local_fields):
                        field.add_subfield("9", "LOCAL")
                    for field in record.get_fields("856"):
                        split_provider(field)
                        update_lu_proxy(field)
                        remove_other_856(record, field)
                    for field in record.get_fields("856"):
                        for note in field.get_subfields("y"):
                            url_notes[note] = 1

                    if record.get_fields("245") or record.get_fields("240"):
                        localf.write(record.as_marc())
                    else:
                        for field in record.get_fields("852"):
                            update_locations(field)
                        if not record.get_fields("901"):
                            print("No 901 for {}".format(record.get_fields("001")[0].data))
                        #munge_mfhd(record)
                        mfhdf.write(record.as_marc())
            except Exception as e:
                traceback.print_exc()
                print("{} : {}".format(mrc, e))
                continue
    for note in sorted(url_notes):
        print("{}".format(note))


if __name__ == "__main__":
    main()
