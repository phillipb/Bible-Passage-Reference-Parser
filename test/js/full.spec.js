      expect(p.parse("lev 1 tniv").osis_and_translations()).toEqual([["Lev.1", "TNIV"]]);
      expect(p.parse("Lev 1 (NET)").osis_and_translations()).toEqual([["Lev.1", "NET"]]);
      return expect(p.parse("lev 1 net").osis_and_translations()).toEqual([["Lev.1", "NET"]]);
