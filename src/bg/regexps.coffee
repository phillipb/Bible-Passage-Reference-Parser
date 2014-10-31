bcv_parser::regexps.space = "[\\s\\xa0]"
bcv_parser::regexps.escaped_passage = ///
	(?:^ | [^\x1f\x1e\dA-Za-zªµºÀ-ÖØ-öø-ɏЀ-ҁ҃-҇Ҋ-ԧḀ-ỿⱠ-Ɀⷠ-ⷿꙀ-꙯ꙴ-꙽ꙿ-ꚗꚟꜢ-ꞈꞋ-ꞎꞐ-ꞓꞠ-Ɦꟸ-ꟿ] )	# Beginning of string or not in the middle of a word or immediately following another book. Only count a book if it's part of a sequence: `Matt5John3` is OK, but not `1Matt5John3`
		(
			# Start inverted book/chapter (cb)
			(?:
				  (?: ch (?: apters? | a?pts?\.? | a?p?s?\.? )? \s*
					\d+ \s* (?: [\u2013\u2014\-] | through | thru | to) \s* \d+ \s*
					(?: from | of | in ) (?: \s+ the \s+ book \s+ of )?\s* )
				| (?: ch (?: apters? | a?pts?\.? | a?p?s?\.? )? \s*
					\d+ \s*
					(?: from | of | in ) (?: \s+ the \s+ book \s+ of )?\s* )
				| (?: \d+ (?: th | nd | st ) \s*
					ch (?: apter | a?pt\.? | a?p?\.? )? \s* #no plurals here since it's a single chapter
					(?: from | of | in ) (?: \s+ the \s+ book \s+ of )? \s* )
			)? # End inverted book/chapter (cb)
			\x1f(\d+)(?:/\d+)?\x1f		#book
				(?:
				    /\d+\x1f				#special Psalm chapters
				  | [\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014]
				  | title (?! [a-z] )		#could be followed by a number
				  | и#{bcv_parser::regexps.space}+сл | глава | глави | verse | гл | - | и
				  | [aаб] (?! \w )			#a-e allows 1:1a
				  | $						#or the end of the string
				 )+
		)
	///gi
# These are the only valid ways to end a potential passage match. The closing parenthesis allows for fully capturing parentheses surrounding translations (ESV**)**.
bcv_parser::regexps.match_end_split = ///
	  \d+ \W* title
	| \d+ \W* и#{bcv_parser::regexps.space}+сл (?: [\s\xa0*]* \.)?
	| \d+ [\s\xa0*]* [aаб] (?! \w )
	| \x1e (?: [\s\xa0*]* [)\]\uff09] )? #ff09 is a full-width closing parenthesis
	| [\d\x1f]+
	///gi
bcv_parser::regexps.control = /[\x1e\x1f]/g
bcv_parser::regexps.pre_book = "[^A-Za-zªµºÀ-ÖØ-öø-ɏЀ-ҁ҃-҇Ҋ-ԧḀ-ỿⱠ-Ɀⷠ-ⷿꙀ-꙯ꙴ-꙽ꙿ-ꚗꚟꜢ-ꞈꞋ-ꞎꞐ-ꞓꞠ-Ɦꟸ-ꟿ]"

bcv_parser::regexps.first = "(?:Първа|1|I)\\.?#{bcv_parser::regexps.space}*"
bcv_parser::regexps.second = "(?:Втора|2|II)\\.?#{bcv_parser::regexps.space}*"
bcv_parser::regexps.third = "(?:Трето|3|III)\\.?#{bcv_parser::regexps.space}*"
bcv_parser::regexps.range_and = "(?:[&\u2013\u2014-]|и|-)"
bcv_parser::regexps.range_only = "(?:[\u2013\u2014-]|-)"
# Each book regexp should return two parenthesized objects: an optional preliminary character and the book itself.
bcv_parser::regexps.get_books = (include_apocrypha, case_sensitive) ->
	books = [
		osis: ["Ps"]
		apocrypha: true
		extra: "2"
		regexp: ///(\b)( # Don't match a preceding \d like usual because we only want to match a valid OSIS, which will never have a preceding digit.
			Ps151
			# Always follwed by ".1"; the regular Psalms parser can handle `Ps151` on its own.
			)(?=\.1)///g # Case-sensitive because we only want to match a valid OSIS.
	,
		osis: ["Gen"]
		regexp: ///(^|[^0-9A-Za-zªµºÀ-ÖØ-öø-ɏЀ-ҁ҃-҇Ҋ-ԧḀ-ỿⱠ-Ɀⷠ-ⷿꙀ-꙯ꙴ-꙽ꙿ-ꚗꚟꜢ-ꞈꞋ-ꞎꞐ-ꞓꞠ-Ɦꟸ-ꟿ])(
		(?:Първа[\s\xa0]*(?:книга[\s\xa0]*Моисеева|Моисеева)|(?:[1I](?:\.[\s\xa0]*Моисеева|[\s\xa0]*Моисеева))|Gen|Бит(?:ие)?)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Exod"]
		regexp: ///(^|[^0-9A-Za-zªµºÀ-ÖØ-öø-ɏЀ-ҁ҃-҇Ҋ-ԧḀ-ỿⱠ-Ɀⷠ-ⷿꙀ-꙯ꙴ-꙽ꙿ-ꚗꚟꜢ-ꞈꞋ-ꞎꞐ-ꞓꞠ-Ɦꟸ-ꟿ])(
		(?:Втора[\s\xa0]*(?:книга[\s\xa0]*Моисеева|Моисеева)|II(?:\.[\s\xa0]*Моисеева|[\s\xa0]*Моисеева)|2(?:\.[\s\xa0]*Моисеева|[\s\xa0]*Моисеева)|Exod|Изх(?:од)?)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Bel"]
		apocrypha: true
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Bel|Бел)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Lev"]
		regexp: ///(^|[^0-9A-Za-zªµºÀ-ÖØ-öø-ɏЀ-ҁ҃-҇Ҋ-ԧḀ-ỿⱠ-Ɀⷠ-ⷿꙀ-꙯ꙴ-꙽ꙿ-ꚗꚟꜢ-ꞈꞋ-ꞎꞐ-ꞓꞠ-Ɦꟸ-ꟿ])(
		(?:Трет(?:а[\s\xa0]*книга[\s\xa0]*Моисеева|о[\s\xa0]*Моисеева)|III(?:\.[\s\xa0]*Моисеева|[\s\xa0]*Моисеева)|3(?:\.[\s\xa0]*Моисеева|[\s\xa0]*Моисеева)|Lev|Лев(?:ит)?)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Num"]
		regexp: ///(^|[^0-9A-Za-zªµºÀ-ÖØ-öø-ɏЀ-ҁ҃-҇Ҋ-ԧḀ-ỿⱠ-Ɀⷠ-ⷿꙀ-꙯ꙴ-꙽ꙿ-ꚗꚟꜢ-ꞈꞋ-ꞎꞐ-ꞓꞠ-Ɦꟸ-ꟿ])(
		(?:IV(?:\.[\s\xa0]*Моисеева|[\s\xa0]*Моисеева)|4(?:\.[\s\xa0]*Моисеева|[\s\xa0]*Моисеева)|Num|Ч(?:етвърта[\s\xa0]*(?:книга[\s\xa0]*Моисеева|Моисеева)|ис(?:ла)?))
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Sir"]
		apocrypha: true
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Премъдрост[\s\xa0]*на[\s\xa0]*Иисус,[\s\xa0]*син[\s\xa0]*Сирахов|Книга[\s\xa0]*(?:Премъдрост[\s\xa0]*на[\s\xa0]*Иисуса,[\s\xa0]*син[\s\xa0]*Сирахов|на[\s\xa0]*Сирах)|Сирахов|Sir)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Wis"]
		apocrypha: true
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Книга[\s\xa0]*(?:Премъдрост[\s\xa0]*Соломонова|на[\s\xa0]*мъдростта)|Премъдрост(?:[\s\xa0]*Соломонова)?|Wis)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Lam"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Книга[\s\xa0]*Плач[\s\xa0]*Иеремиев|П(?:\.[\s\xa0]*[ИЙ]ер|[\s\xa0]*[ИЙ]ер|лач(?:ът[\s\xa0]*на[\s\xa0]*(?:[ИЙ]еремия|Еремия)|[\s\xa0]*(?:Иеремиев|Еремиев))?)|Lam)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["EpJer"]
		apocrypha: true
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Послание[\s\xa0]*на[\s\xa0]*Иеремия|EpJer)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Rev"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Апокалипсис|Откр(?:овение(?:то[\s\xa0]*на[\s\xa0]*[ИЙ]оан|[\s\xa0]*на[\s\xa0]*(?:св(?:\.[\s\xa0]*Иоана[\s\xa0]*Богослова|[\s\xa0]*Иоана[\s\xa0]*Богослова)|[ИЙ]оан))?)?|Rev)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["PrMan"]
		apocrypha: true
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		PrMan
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Deut"]
		regexp: ///(^|[^0-9A-Za-zªµºÀ-ÖØ-öø-ɏЀ-ҁ҃-҇Ҋ-ԧḀ-ỿⱠ-Ɀⷠ-ⷿꙀ-꙯ꙴ-꙽ꙿ-ꚗꚟꜢ-ꞈꞋ-ꞎꞐ-ꞓꞠ-Ɦꟸ-ꟿ])(
		(?:Пета[\s\xa0]*книга[\s\xa0]*Моисеева|5[\s\xa0]*Моисеева|Deut|Вт(?:орозак(?:оние)?)?)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Josh"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Книга[\s\xa0]*(?:на[\s\xa0]*Исус[\s\xa0]*Навиев|Иисус[\s\xa0]*Навин)|Josh|И(?:исус[\s\xa0]*Навин|с(?:ус[\s\xa0]*Нави(?:ев|н)|\.[\s\xa0]*Нав|[\s\xa0]*Нав)|\.[\s\xa0]*Н|[\s\xa0]*Н))
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Judg"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Книга[\s\xa0]*(?:Съдии[\s\xa0]*Израилеви|на[\s\xa0]*съдиите)|Judg|Съд(?:ии(?:[\s\xa0]*Израилеви)?)?)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Ruth"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Книга[\s\xa0]*Рут|Ruth|Рут)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["1Esd"]
		apocrypha: true
		regexp: ///(^|[^0-9A-Za-zªµºÀ-ÖØ-öø-ɏЀ-ҁ҃-҇Ҋ-ԧḀ-ỿⱠ-Ɀⷠ-ⷿꙀ-꙯ꙴ-꙽ꙿ-ꚗꚟꜢ-ꞈꞋ-ꞎꞐ-ꞓꞠ-Ɦꟸ-ꟿ])(
		(?:Първа[\s\xa0]*(?:книга[\s\xa0]*на[\s\xa0]*Ездра|Ездра)|I(?:\.[\s\xa0]*Ездра|[\s\xa0]*Ездра)|1(?:\.[\s\xa0]*Ездра|[\s\xa0]*Ездра|Esd))
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["2Esd"]
		apocrypha: true
		regexp: ///(^|[^0-9A-Za-zªµºÀ-ÖØ-öø-ɏЀ-ҁ҃-҇Ҋ-ԧḀ-ỿⱠ-Ɀⷠ-ⷿꙀ-꙯ꙴ-꙽ꙿ-ꚗꚟꜢ-ꞈꞋ-ꞎꞐ-ꞓꞠ-Ɦꟸ-ꟿ])(
		(?:Втора[\s\xa0]*(?:книга[\s\xa0]*на[\s\xa0]*Ездра|Ездра)|II(?:\.[\s\xa0]*Ездра|[\s\xa0]*Ездра)|2(?:\.[\s\xa0]*Ездра|[\s\xa0]*Ездра|Esd))
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Isa"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Книга[\s\xa0]*на[\s\xa0]*пророк[\s\xa0]*Исаия|Isa|Ис(?:а(?:ия|я))?)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["2Sam"]
		regexp: ///(^|[^0-9A-Za-zªµºÀ-ÖØ-öø-ɏЀ-ҁ҃-҇Ҋ-ԧḀ-ỿⱠ-Ɀⷠ-ⷿꙀ-꙯ꙴ-꙽ꙿ-ꚗꚟꜢ-ꞈꞋ-ꞎꞐ-ꞓꞠ-Ɦꟸ-ꟿ])(
		(?:Втора[\s\xa0]*(?:Книга[\s\xa0]*на[\s\xa0]*царете|книга[\s\xa0]*(?:на[\s\xa0]*Самуил|Царства)|Самуил|Цар(?:ства|е))|II(?:\.[\s\xa0]*(?:Книга[\s\xa0]*на[\s\xa0]*царете|Самуил|Цар(?:ства|е))|[\s\xa0]*(?:Книга[\s\xa0]*на[\s\xa0]*царете|Самуил|Цар(?:ства|е)))|2(?:\.[\s\xa0]*(?:Книга[\s\xa0]*на[\s\xa0]*царете|Самуил|Цар(?:ства|е))|Sam|[\s\xa0]*(?:Книга[\s\xa0]*на[\s\xa0]*царете|Самуил|Ц(?:ар(?:ства|е))?)))
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["1Sam"]
		regexp: ///(^|[^0-9A-Za-zªµºÀ-ÖØ-öø-ɏЀ-ҁ҃-҇Ҋ-ԧḀ-ỿⱠ-Ɀⷠ-ⷿꙀ-꙯ꙴ-꙽ꙿ-ꚗꚟꜢ-ꞈꞋ-ꞎꞐ-ꞓꞠ-Ɦꟸ-ꟿ])(
		(?:Първа[\s\xa0]*(?:Книга[\s\xa0]*на[\s\xa0]*царете|книга[\s\xa0]*(?:на[\s\xa0]*Самуил|Царства)|Самуил|Цар(?:ства|е))|I(?:\.[\s\xa0]*(?:Книга[\s\xa0]*на[\s\xa0]*царете|Самуил|Цар(?:ства|е))|[\s\xa0]*(?:Книга[\s\xa0]*на[\s\xa0]*царете|Самуил|Цар(?:ства|е)))|1(?:\.[\s\xa0]*(?:Книга[\s\xa0]*на[\s\xa0]*царете|Самуил|Цар(?:ства|е))|Sam|[\s\xa0]*(?:Книга[\s\xa0]*на[\s\xa0]*царете|Самуил|Ц(?:ар(?:ства|е))?)))
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["2Kgs"]
		regexp: ///(^|[^0-9A-Za-zªµºÀ-ÖØ-öø-ɏЀ-ҁ҃-҇Ҋ-ԧḀ-ỿⱠ-Ɀⷠ-ⷿꙀ-꙯ꙴ-꙽ꙿ-ꚗꚟꜢ-ꞈꞋ-ꞎꞐ-ꞓꞠ-Ɦꟸ-ꟿ])(
		(?:Четвърта[\s\xa0]*(?:Книга[\s\xa0]*на[\s\xa0]*царете|книга[\s\xa0]*(?:на[\s\xa0]*царете|Царства)|Цар(?:ства|е))|IV(?:\.[\s\xa0]*(?:Книга[\s\xa0]*на[\s\xa0]*царете|Цар(?:ства|е))|[\s\xa0]*(?:Книга[\s\xa0]*на[\s\xa0]*царете|Цар(?:ства|е)))|2Kgs|4(?:\.[\s\xa0]*(?:Книга[\s\xa0]*на[\s\xa0]*царете|Цар(?:ства|е))|[\s\xa0]*(?:Книга[\s\xa0]*на[\s\xa0]*царете|Ц(?:ар(?:ства|е))?)))
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["1Kgs"]
		regexp: ///(^|[^0-9A-Za-zªµºÀ-ÖØ-öø-ɏЀ-ҁ҃-҇Ҋ-ԧḀ-ỿⱠ-Ɀⷠ-ⷿꙀ-꙯ꙴ-꙽ꙿ-ꚗꚟꜢ-ꞈꞋ-ꞎꞐ-ꞓꞠ-Ɦꟸ-ꟿ])(
		(?:Трет(?:а[\s\xa0]*книга[\s\xa0]*(?:на[\s\xa0]*царете|Царства)|о[\s\xa0]*(?:Книга[\s\xa0]*на[\s\xa0]*царете|Цар(?:ства|е)))|III(?:\.[\s\xa0]*(?:Книга[\s\xa0]*на[\s\xa0]*царете|Цар(?:ства|е))|[\s\xa0]*(?:Книга[\s\xa0]*на[\s\xa0]*царете|Цар(?:ства|е)))|1Kgs|3(?:\.[\s\xa0]*(?:Книга[\s\xa0]*на[\s\xa0]*царете|Цар(?:ства|е))|[\s\xa0]*(?:Книга[\s\xa0]*на[\s\xa0]*царете|Ц(?:ар(?:ства|е))?)))
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["2Chr"]
		regexp: ///(^|[^0-9A-Za-zªµºÀ-ÖØ-öø-ɏЀ-ҁ҃-҇Ҋ-ԧḀ-ỿⱠ-Ɀⷠ-ⷿꙀ-꙯ꙴ-꙽ꙿ-ꚗꚟꜢ-ꞈꞋ-ꞎꞐ-ꞓꞠ-Ɦꟸ-ꟿ])(
		(?:или[\s\xa0]*Втора[\s\xa0]*книга[\s\xa0]*Паралипоменон|Втора[\s\xa0]*(?:Книга[\s\xa0]*на[\s\xa0]*летописите|книга[\s\xa0]*(?:Паралипоменон|на[\s\xa0]*летописите)|Лет(?:описи)?)|II(?:\.[\s\xa0]*(?:Книга[\s\xa0]*на[\s\xa0]*летописите|Лет(?:описи)?)|[\s\xa0]*(?:Книга[\s\xa0]*на[\s\xa0]*летописите|Лет(?:описи)?))|2(?:\.[\s\xa0]*(?:Книга[\s\xa0]*на[\s\xa0]*летописите|Лет(?:описи)?)|[\s\xa0]*(?:Книга[\s\xa0]*на[\s\xa0]*летописите|Лет(?:описи)?)|Chr))
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["1Chr"]
		regexp: ///(^|[^0-9A-Za-zªµºÀ-ÖØ-öø-ɏЀ-ҁ҃-҇Ҋ-ԧḀ-ỿⱠ-Ɀⷠ-ⷿꙀ-꙯ꙴ-꙽ꙿ-ꚗꚟꜢ-ꞈꞋ-ꞎꞐ-ꞓꞠ-Ɦꟸ-ꟿ])(
		(?:или[\s\xa0]*Първа[\s\xa0]*книга[\s\xa0]*Паралипоменон|Първа[\s\xa0]*(?:Книга[\s\xa0]*на[\s\xa0]*летописите|книга[\s\xa0]*(?:Паралипоменон|на[\s\xa0]*летописите)|Лет(?:описи)?)|I(?:\.[\s\xa0]*(?:Книга[\s\xa0]*на[\s\xa0]*летописите|Лет(?:описи)?)|[\s\xa0]*(?:Книга[\s\xa0]*на[\s\xa0]*летописите|Лет(?:описи)?))|1(?:\.[\s\xa0]*(?:Книга[\s\xa0]*на[\s\xa0]*летописите|Лет(?:описи)?)|[\s\xa0]*(?:Книга[\s\xa0]*на[\s\xa0]*летописите|Лет(?:описи)?)|Chr))
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Ezra"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Книга[\s\xa0]*на[\s\xa0]*Ездра|Ezra|Езд(?:ра)?)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Neh"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Книга[\s\xa0]*на[\s\xa0]*Неемия|Неем(?:ия)?|Neh)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["GkEsth"]
		apocrypha: true
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		GkEsth
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Esth"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Книга[\s\xa0]*Естир|Esth|Ест(?:ир)?)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Job"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Книга[\s\xa0]*на[\s\xa0]*(?:Иова?|Йов)|Job|[ИЙ]ов)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Ps"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Ps|Пс(?:ал(?:тир|ми|ом))?)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["PrAzar"]
		apocrypha: true
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		PrAzar
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Prov"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Книга[\s\xa0]*Притчи[\s\xa0]*Соломонови|Prov|Пр(?:итчи(?:[\s\xa0]*Соломонови)?)?)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Eccl"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Книга[\s\xa0]*на[\s\xa0]*Еклисиаста[\s\xa0]*или[\s\xa0]*Проповедника|Проповедника|Eccl|Екл(?:есиаст|исиаста?)?)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["SgThree"]
		apocrypha: true
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		SgThree
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Song"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Книга[\s\xa0]*Песен[\s\xa0]*на[\s\xa0]*Песните,[\s\xa0]*от[\s\xa0]*Соломона|Song|П(?:\.[\s\xa0]*П|[\s\xa0]*П|ес(?:ен[\s\xa0]*на[\s\xa0]*песните)?))
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Jer"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Книга[\s\xa0]*на[\s\xa0]*пророк[\s\xa0]*(?:[ИЙ]еремия|Еремия)|Jer|(?:[ИЙ]ер(?:емия)?)|Ер(?:емия)?)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Ezek"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Книга[\s\xa0]*на[\s\xa0]*пророк[\s\xa0]*(?:Иезекииля|Езекиил)|Ezek|Езек(?:и(?:ил|л))?|Иез(?:екииля?)?|Йез(?:екиил)?)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Dan"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Книга[\s\xa0]*на[\s\xa0]*пророк[\s\xa0]*Даниила?|Dan|Дан(?:аил|иила?)?)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Hos"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Книга[\s\xa0]*на[\s\xa0]*пророк[\s\xa0]*Осия|Hos|Ос(?:ия)?)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Joel"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Книга[\s\xa0]*на[\s\xa0]*пророк[\s\xa0]*Иоиля?|Joel|Иоиля?|Йоил)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Amos"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Книга[\s\xa0]*на[\s\xa0]*пророк[\s\xa0]*Амоса?|Amos|Ам(?:оса?)?)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Obad"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Книга[\s\xa0]*на[\s\xa0]*пророк[\s\xa0]*Авди[ий]|Obad|Авд(?:и[ий])?)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Jonah"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Книга[\s\xa0]*на[\s\xa0]*пророк[\s\xa0]*Иона|Jonah|[ИЙ]она?)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Mic"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Книга[\s\xa0]*на[\s\xa0]*пророк[\s\xa0]*Михе[ий]|Mic|Мих(?:е[ий])?)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Nah"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Книга[\s\xa0]*на[\s\xa0]*пророк[\s\xa0]*Наума?|Наума?|Nah)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Hab"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Книга[\s\xa0]*на[\s\xa0]*пророк[\s\xa0]*Авакума?|Hab|Ав(?:ак(?:ума?)?)?)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Zeph"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Книга[\s\xa0]*на[\s\xa0]*пророк[\s\xa0]*Софония|Zeph|Соф(?:они[ийя])?)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Hag"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Книга[\s\xa0]*на[\s\xa0]*пророк[\s\xa0]*Аге[ий]|Hag|Аг(?:е[ий])?)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Zech"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Книга[\s\xa0]*на[\s\xa0]*пророк[\s\xa0]*Захария|Zech|Зах(?:ария)?)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Mal"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Книга[\s\xa0]*на[\s\xa0]*пророк[\s\xa0]*Малахия|Mal|Мал(?:ахия)?)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Matt"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Евангелие[\s\xa0]*от[\s\xa0]*Мате[ий]|От[\s\xa0]*Матея(?:[\s\xa0]*свето[\s\xa0]*Евангелие)?|Matt|Мат(?:е[ий])?)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Mark"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Евангелие[\s\xa0]*от[\s\xa0]*Марко|От[\s\xa0]*Марка(?:[\s\xa0]*свето[\s\xa0]*Евангелие)?|Mark|Марко?)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Luke"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Евангелие[\s\xa0]*от[\s\xa0]*Лука|От[\s\xa0]*Лука(?:[\s\xa0]*свето[\s\xa0]*Евангелие)?|Luke|Лука)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["1John"]
		regexp: ///(^|[^0-9A-Za-zªµºÀ-ÖØ-öø-ɏЀ-ҁ҃-҇Ҋ-ԧḀ-ỿⱠ-Ɀⷠ-ⷿꙀ-꙯ꙴ-꙽ꙿ-ꚗꚟꜢ-ꞈꞋ-ꞎꞐ-ꞓꞠ-Ɦꟸ-ꟿ])(
		(?:Първ(?:о[\s\xa0]*(?:съборно[\s\xa0]*послание[\s\xa0]*на[\s\xa0]*св(?:\.[\s\xa0]*ап(?:\.[\s\xa0]*Иоана[\s\xa0]*Богослова|[\s\xa0]*Иоана[\s\xa0]*Богослова)|[\s\xa0]*ап(?:\.[\s\xa0]*Иоана[\s\xa0]*Богослова|[\s\xa0]*Иоана[\s\xa0]*Богослова))|послание[\s\xa0]*на[\s\xa0]*[ИЙ]оан)|а[\s\xa0]*(?:[ИЙ]оан(?:ово)?))|I(?:\.[\s\xa0]*(?:[ИЙ]оан(?:ово)?)|[\s\xa0]*(?:[ИЙ]оан(?:ово)?))|1(?:\.[\s\xa0]*(?:[ИЙ]оан(?:ово)?)|[\s\xa0]*(?:[ИЙ]оан(?:ово)?)|John))
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["2John"]
		regexp: ///(^|[^0-9A-Za-zªµºÀ-ÖØ-öø-ɏЀ-ҁ҃-҇Ҋ-ԧḀ-ỿⱠ-Ɀⷠ-ⷿꙀ-꙯ꙴ-꙽ꙿ-ꚗꚟꜢ-ꞈꞋ-ꞎꞐ-ꞓꞠ-Ɦꟸ-ꟿ])(
		(?:Втор(?:о[\s\xa0]*(?:съборно[\s\xa0]*послание[\s\xa0]*на[\s\xa0]*св(?:\.[\s\xa0]*ап(?:\.[\s\xa0]*Иоана[\s\xa0]*Богослова|[\s\xa0]*Иоана[\s\xa0]*Богослова)|[\s\xa0]*ап(?:\.[\s\xa0]*Иоана[\s\xa0]*Богослова|[\s\xa0]*Иоана[\s\xa0]*Богослова))|послание[\s\xa0]*на[\s\xa0]*[ИЙ]оан)|а[\s\xa0]*(?:[ИЙ]оан(?:ово)?))|II(?:\.[\s\xa0]*(?:[ИЙ]оан(?:ово)?)|[\s\xa0]*(?:[ИЙ]оан(?:ово)?))|2(?:\.[\s\xa0]*(?:[ИЙ]оан(?:ово)?)|[\s\xa0]*(?:[ИЙ]оан(?:ово)?)|John))
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["3John"]
		regexp: ///(^|[^0-9A-Za-zªµºÀ-ÖØ-öø-ɏЀ-ҁ҃-҇Ҋ-ԧḀ-ỿⱠ-Ɀⷠ-ⷿꙀ-꙯ꙴ-꙽ꙿ-ꚗꚟꜢ-ꞈꞋ-ꞎꞐ-ꞓꞠ-Ɦꟸ-ꟿ])(
		(?:Трето[\s\xa0]*(?:съборно[\s\xa0]*послание[\s\xa0]*на[\s\xa0]*св(?:\.[\s\xa0]*ап(?:\.[\s\xa0]*Иоана[\s\xa0]*Богослова|[\s\xa0]*Иоана[\s\xa0]*Богослова)|[\s\xa0]*ап(?:\.[\s\xa0]*Иоана[\s\xa0]*Богослова|[\s\xa0]*Иоана[\s\xa0]*Богослова))|послание[\s\xa0]*на[\s\xa0]*[ИЙ]оан|(?:[ИЙ]оан(?:ово)?))|III(?:\.[\s\xa0]*(?:[ИЙ]оан(?:ово)?)|[\s\xa0]*(?:[ИЙ]оан(?:ово)?))|3(?:\.[\s\xa0]*(?:[ИЙ]оан(?:ово)?)|[\s\xa0]*(?:[ИЙ]оан(?:ово)?)|John))
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["John"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Евангелие[\s\xa0]*от[\s\xa0]*[ИЙ]оан|От[\s\xa0]*Иоана(?:[\s\xa0]*свето[\s\xa0]*Евангелие)?|John|[ИЙ]оан)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Acts"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Апостол|Acts|Д(?:\.[\s\xa0]*А|е(?:ла|ян(?:ия(?:та[\s\xa0]*на[\s\xa0]*апостолите|[\s\xa0]*на[\s\xa0]*(?:светите[\s\xa0]*Апостоли|апостолите))?)?)|[\s\xa0]*А))
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Rom"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Послание[\s\xa0]*(?:на[\s\xa0]*св(?:\.[\s\xa0]*ап(?:\.[\s\xa0]*Павла[\s\xa0]*до[\s\xa0]*Римляни|[\s\xa0]*Павла[\s\xa0]*до[\s\xa0]*Римляни)|[\s\xa0]*ап(?:\.[\s\xa0]*Павла[\s\xa0]*до[\s\xa0]*Римляни|[\s\xa0]*Павла[\s\xa0]*до[\s\xa0]*Римляни))|към[\s\xa0]*римляните)|римляните|Rom|Рим(?:л(?:яни)?)?)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["2Cor"]
		regexp: ///(^|[^0-9A-Za-zªµºÀ-ÖØ-öø-ɏЀ-ҁ҃-҇Ҋ-ԧḀ-ỿⱠ-Ɀⷠ-ⷿꙀ-꙯ꙴ-꙽ꙿ-ꚗꚟꜢ-ꞈꞋ-ꞎꞐ-ꞓꞠ-Ɦꟸ-ꟿ])(
		(?:Втор(?:о[\s\xa0]*послание[\s\xa0]*(?:на[\s\xa0]*св(?:\.[\s\xa0]*ап(?:\.[\s\xa0]*Павла[\s\xa0]*до[\s\xa0]*Коринтяни|[\s\xa0]*Павла[\s\xa0]*до[\s\xa0]*Коринтяни)|[\s\xa0]*ап(?:\.[\s\xa0]*Павла[\s\xa0]*до[\s\xa0]*Коринтяни|[\s\xa0]*Павла[\s\xa0]*до[\s\xa0]*Коринтяни))|към[\s\xa0]*коринтяните)|а[\s\xa0]*Кор(?:интяни(?:те)?)?)|II(?:\.[\s\xa0]*Кор(?:интяни(?:те)?)?|[\s\xa0]*Кор(?:интяни(?:те)?)?)|2(?:\.[\s\xa0]*Кор(?:интяни(?:те)?)?|[\s\xa0]*Кор(?:интяни(?:те)?)?|Cor))
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["1Cor"]
		regexp: ///(^|[^0-9A-Za-zªµºÀ-ÖØ-öø-ɏЀ-ҁ҃-҇Ҋ-ԧḀ-ỿⱠ-Ɀⷠ-ⷿꙀ-꙯ꙴ-꙽ꙿ-ꚗꚟꜢ-ꞈꞋ-ꞎꞐ-ꞓꞠ-Ɦꟸ-ꟿ])(
		(?:Първ(?:о[\s\xa0]*послание[\s\xa0]*(?:на[\s\xa0]*св(?:\.[\s\xa0]*ап(?:\.[\s\xa0]*Павла[\s\xa0]*до[\s\xa0]*Коринтяни|[\s\xa0]*Павла[\s\xa0]*до[\s\xa0]*Коринтяни)|[\s\xa0]*ап(?:\.[\s\xa0]*Павла[\s\xa0]*до[\s\xa0]*Коринтяни|[\s\xa0]*Павла[\s\xa0]*до[\s\xa0]*Коринтяни))|към[\s\xa0]*коринтяните)|а[\s\xa0]*Кор(?:интяни(?:те)?)?)|I(?:\.[\s\xa0]*Кор(?:интяни(?:те)?)?|[\s\xa0]*Кор(?:интяни(?:те)?)?)|1(?:\.[\s\xa0]*Кор(?:интяни(?:те)?)?|[\s\xa0]*Кор(?:интяни(?:те)?)?|Cor))
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Gal"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Послание[\s\xa0]*(?:на[\s\xa0]*св(?:\.[\s\xa0]*ап(?:\.[\s\xa0]*Павла[\s\xa0]*до[\s\xa0]*Галатяни|[\s\xa0]*Павла[\s\xa0]*до[\s\xa0]*Галатяни)|[\s\xa0]*ап(?:\.[\s\xa0]*Павла[\s\xa0]*до[\s\xa0]*Галатяни|[\s\xa0]*Павла[\s\xa0]*до[\s\xa0]*Галатяни))|към[\s\xa0]*галатяните)|Gal|Гал(?:атяни(?:те)?)?)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Eph"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Послание[\s\xa0]*(?:на[\s\xa0]*св(?:\.[\s\xa0]*ап(?:\.[\s\xa0]*Павла[\s\xa0]*до[\s\xa0]*Ефесяни|[\s\xa0]*Павла[\s\xa0]*до[\s\xa0]*Ефесяни)|[\s\xa0]*ап(?:\.[\s\xa0]*Павла[\s\xa0]*до[\s\xa0]*Ефесяни|[\s\xa0]*Павла[\s\xa0]*до[\s\xa0]*Ефесяни))|към[\s\xa0]*ефесяните)|Eph|Еф(?:есяни(?:те)?)?)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Phil"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Послание[\s\xa0]*(?:на[\s\xa0]*св(?:\.[\s\xa0]*ап(?:\.[\s\xa0]*Павла[\s\xa0]*до[\s\xa0]*Филипяни|[\s\xa0]*Павла[\s\xa0]*до[\s\xa0]*Филипяни)|[\s\xa0]*ап(?:\.[\s\xa0]*Павла[\s\xa0]*до[\s\xa0]*Филипяни|[\s\xa0]*Павла[\s\xa0]*до[\s\xa0]*Филипяни))|към[\s\xa0]*филипяните)|Phil|Фил(?:ипяни(?:те)?)?)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Col"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Послание[\s\xa0]*(?:на[\s\xa0]*св(?:\.[\s\xa0]*ап(?:\.[\s\xa0]*Павла[\s\xa0]*до[\s\xa0]*Колосяни|[\s\xa0]*Павла[\s\xa0]*до[\s\xa0]*Колосяни)|[\s\xa0]*ап(?:\.[\s\xa0]*Павла[\s\xa0]*до[\s\xa0]*Колосяни|[\s\xa0]*Павла[\s\xa0]*до[\s\xa0]*Колосяни))|към[\s\xa0]*колосяните)|Col|Кол(?:осяни(?:те)?)?)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["2Thess"]
		regexp: ///(^|[^0-9A-Za-zªµºÀ-ÖØ-öø-ɏЀ-ҁ҃-҇Ҋ-ԧḀ-ỿⱠ-Ɀⷠ-ⷿꙀ-꙯ꙴ-꙽ꙿ-ꚗꚟꜢ-ꞈꞋ-ꞎꞐ-ꞓꞠ-Ɦꟸ-ꟿ])(
		(?:Втор(?:о[\s\xa0]*послание[\s\xa0]*(?:на[\s\xa0]*св(?:\.[\s\xa0]*ап(?:\.[\s\xa0]*Павла[\s\xa0]*до[\s\xa0]*Солуняни|[\s\xa0]*Павла[\s\xa0]*до[\s\xa0]*Солуняни)|[\s\xa0]*ап(?:\.[\s\xa0]*Павла[\s\xa0]*до[\s\xa0]*Солуняни|[\s\xa0]*Павла[\s\xa0]*до[\s\xa0]*Солуняни))|към[\s\xa0]*солунците)|а[\s\xa0]*Сол(?:унци(?:те)?)?)|II(?:\.[\s\xa0]*Сол(?:унци(?:те)?)?|[\s\xa0]*Сол(?:унци(?:те)?)?)|2(?:\.[\s\xa0]*Сол(?:унци(?:те)?)?|Thess|[\s\xa0]*Сол(?:унци(?:те)?)?))
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["1Thess"]
		regexp: ///(^|[^0-9A-Za-zªµºÀ-ÖØ-öø-ɏЀ-ҁ҃-҇Ҋ-ԧḀ-ỿⱠ-Ɀⷠ-ⷿꙀ-꙯ꙴ-꙽ꙿ-ꚗꚟꜢ-ꞈꞋ-ꞎꞐ-ꞓꞠ-Ɦꟸ-ꟿ])(
		(?:Първ(?:о[\s\xa0]*послание[\s\xa0]*(?:на[\s\xa0]*св(?:\.[\s\xa0]*ап(?:\.[\s\xa0]*Павла[\s\xa0]*до[\s\xa0]*Солуняни|[\s\xa0]*Павла[\s\xa0]*до[\s\xa0]*Солуняни)|[\s\xa0]*ап(?:\.[\s\xa0]*Павла[\s\xa0]*до[\s\xa0]*Солуняни|[\s\xa0]*Павла[\s\xa0]*до[\s\xa0]*Солуняни))|към[\s\xa0]*солунците)|а[\s\xa0]*Сол(?:унци(?:те)?)?)|1(?:\.[\s\xa0]*Сол(?:унци(?:те)?)?|Thess|[\s\xa0]*Сол(?:унци(?:те)?)?)|I(?:\.[\s\xa0]*Сол(?:унци(?:те)?)?|[\s\xa0]*Сол(?:унци(?:те)?)?))
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["2Tim"]
		regexp: ///(^|[^0-9A-Za-zªµºÀ-ÖØ-öø-ɏЀ-ҁ҃-҇Ҋ-ԧḀ-ỿⱠ-Ɀⷠ-ⷿꙀ-꙯ꙴ-꙽ꙿ-ꚗꚟꜢ-ꞈꞋ-ꞎꞐ-ꞓꞠ-Ɦꟸ-ꟿ])(
		(?:Втор(?:о[\s\xa0]*послание[\s\xa0]*(?:на[\s\xa0]*св(?:\.[\s\xa0]*ап(?:\.[\s\xa0]*Павла[\s\xa0]*до[\s\xa0]*Тимотея|[\s\xa0]*Павла[\s\xa0]*до[\s\xa0]*Тимотея)|[\s\xa0]*ап(?:\.[\s\xa0]*Павла[\s\xa0]*до[\s\xa0]*Тимотея|[\s\xa0]*Павла[\s\xa0]*до[\s\xa0]*Тимотея))|към[\s\xa0]*Тимоте[ий])|а[\s\xa0]*Тим(?:оте[ий])?)|II(?:\.[\s\xa0]*Тим(?:оте[ий])?|[\s\xa0]*Тим(?:оте[ий])?)|2(?:\.[\s\xa0]*Тим(?:оте[ий])?|[\s\xa0]*Тим(?:оте[ий])?|Tim))
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["1Tim"]
		regexp: ///(^|[^0-9A-Za-zªµºÀ-ÖØ-öø-ɏЀ-ҁ҃-҇Ҋ-ԧḀ-ỿⱠ-Ɀⷠ-ⷿꙀ-꙯ꙴ-꙽ꙿ-ꚗꚟꜢ-ꞈꞋ-ꞎꞐ-ꞓꞠ-Ɦꟸ-ꟿ])(
		(?:Първ(?:о[\s\xa0]*послание[\s\xa0]*(?:на[\s\xa0]*св(?:\.[\s\xa0]*ап(?:\.[\s\xa0]*Павла[\s\xa0]*до[\s\xa0]*Тимотея|[\s\xa0]*Павла[\s\xa0]*до[\s\xa0]*Тимотея)|[\s\xa0]*ап(?:\.[\s\xa0]*Павла[\s\xa0]*до[\s\xa0]*Тимотея|[\s\xa0]*Павла[\s\xa0]*до[\s\xa0]*Тимотея))|към[\s\xa0]*Тимоте[ий])|а[\s\xa0]*Тим(?:оте[ий])?)|I(?:\.[\s\xa0]*Тим(?:оте[ий])?|[\s\xa0]*Тим(?:оте[ий])?)|1(?:\.[\s\xa0]*Тим(?:оте[ий])?|[\s\xa0]*Тим(?:оте[ий])?|Tim))
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Titus"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Послание[\s\xa0]*(?:на[\s\xa0]*св(?:\.[\s\xa0]*ап(?:\.[\s\xa0]*Павла[\s\xa0]*до[\s\xa0]*Тита|[\s\xa0]*Павла[\s\xa0]*до[\s\xa0]*Тита)|[\s\xa0]*ап(?:\.[\s\xa0]*Павла[\s\xa0]*до[\s\xa0]*Тита|[\s\xa0]*Павла[\s\xa0]*до[\s\xa0]*Тита))|към[\s\xa0]*Тит)|Titus|Тит)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Phlm"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Послание[\s\xa0]*(?:на[\s\xa0]*св(?:\.[\s\xa0]*ап(?:\.[\s\xa0]*Павла[\s\xa0]*до[\s\xa0]*Филимона|[\s\xa0]*Павла[\s\xa0]*до[\s\xa0]*Филимона)|[\s\xa0]*ап(?:\.[\s\xa0]*Павла[\s\xa0]*до[\s\xa0]*Филимона|[\s\xa0]*Павла[\s\xa0]*до[\s\xa0]*Филимона))|към[\s\xa0]*Филимон)|Филим(?:он)?|Phlm)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Heb"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Послание[\s\xa0]*(?:на[\s\xa0]*св(?:\.[\s\xa0]*ап(?:\.[\s\xa0]*Павла[\s\xa0]*до[\s\xa0]*Евреите|[\s\xa0]*Павла[\s\xa0]*до[\s\xa0]*Евреите)|[\s\xa0]*ап(?:\.[\s\xa0]*Павла[\s\xa0]*до[\s\xa0]*Евреите|[\s\xa0]*Павла[\s\xa0]*до[\s\xa0]*Евреите))|към[\s\xa0]*евреите)|Heb|Евр(?:еи(?:те)?)?)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Jas"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Съборно[\s\xa0]*послание[\s\xa0]*на[\s\xa0]*св(?:\.[\s\xa0]*ап(?:\.[\s\xa0]*Иакова|[\s\xa0]*Иакова)|[\s\xa0]*ап(?:\.[\s\xa0]*Иакова|[\s\xa0]*Иакова))|Послание[\s\xa0]*на[\s\xa0]*Яков|Jas|Як(?:ов)?)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["2Pet"]
		regexp: ///(^|[^0-9A-Za-zªµºÀ-ÖØ-öø-ɏЀ-ҁ҃-҇Ҋ-ԧḀ-ỿⱠ-Ɀⷠ-ⷿꙀ-꙯ꙴ-꙽ꙿ-ꚗꚟꜢ-ꞈꞋ-ꞎꞐ-ꞓꞠ-Ɦꟸ-ꟿ])(
		(?:Втор(?:о[\s\xa0]*(?:съборно[\s\xa0]*послание[\s\xa0]*на[\s\xa0]*св(?:\.[\s\xa0]*ап(?:\.[\s\xa0]*Петра|[\s\xa0]*Петра)|[\s\xa0]*ап(?:\.[\s\xa0]*Петра|[\s\xa0]*Петра))|послание[\s\xa0]*на[\s\xa0]*Петър)|а[\s\xa0]*Пет(?:ър|р(?:ово)?)?)|II(?:\.[\s\xa0]*Пет(?:ър|р(?:ово)?)?|[\s\xa0]*Пет(?:ър|р(?:ово)?)?)|2(?:\.[\s\xa0]*Пет(?:ър|р(?:ово)?)?|[\s\xa0]*Пет(?:ър|р(?:ово)?)?|Pet))
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["1Pet"]
		regexp: ///(^|[^0-9A-Za-zªµºÀ-ÖØ-öø-ɏЀ-ҁ҃-҇Ҋ-ԧḀ-ỿⱠ-Ɀⷠ-ⷿꙀ-꙯ꙴ-꙽ꙿ-ꚗꚟꜢ-ꞈꞋ-ꞎꞐ-ꞓꞠ-Ɦꟸ-ꟿ])(
		(?:Първ(?:о[\s\xa0]*(?:съборно[\s\xa0]*послание[\s\xa0]*на[\s\xa0]*св(?:\.[\s\xa0]*ап(?:\.[\s\xa0]*Петра|[\s\xa0]*Петра)|[\s\xa0]*ап(?:\.[\s\xa0]*Петра|[\s\xa0]*Петра))|послание[\s\xa0]*на[\s\xa0]*Петър)|а[\s\xa0]*Пет(?:ър|р(?:ово)?)?)|I(?:\.[\s\xa0]*Пет(?:ър|р(?:ово)?)?|[\s\xa0]*Пет(?:ър|р(?:ово)?)?)|1(?:\.[\s\xa0]*Пет(?:ър|р(?:ово)?)?|[\s\xa0]*Пет(?:ър|р(?:ово)?)?|Pet))
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Jude"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Съборно[\s\xa0]*послание[\s\xa0]*на[\s\xa0]*св(?:\.[\s\xa0]*ап(?:\.[\s\xa0]*Иуда|[\s\xa0]*Иуда)|[\s\xa0]*ап(?:\.[\s\xa0]*Иуда|[\s\xa0]*Иуда))|Послание[\s\xa0]*на[\s\xa0]*Юда|Jude|Юда)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Tob"]
		apocrypha: true
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Книга[\s\xa0]*(?:за[\s\xa0]*Тобия|на[\s\xa0]*Товита?)|То(?:бия|вита?)|Tob)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Jdt"]
		apocrypha: true
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Книга[\s\xa0]*(?:за[\s\xa0]*Юдита|Иудит)|Иудит|Jdt)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Bar"]
		apocrypha: true
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Книга[\s\xa0]*на[\s\xa0]*(?:пророк[\s\xa0]*Варуха|Барух)|Варуха?|Bar)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Sus"]
		apocrypha: true
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		(?:Sus|Сус)
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["2Macc"]
		apocrypha: true
		regexp: ///(^|[^0-9A-Za-zªµºÀ-ÖØ-öø-ɏЀ-ҁ҃-҇Ҋ-ԧḀ-ỿⱠ-Ɀⷠ-ⷿꙀ-꙯ꙴ-꙽ꙿ-ꚗꚟꜢ-ꞈꞋ-ꞎꞐ-ꞓꞠ-Ɦꟸ-ꟿ])(
		(?:Втора[\s\xa0]*(?:книга[\s\xa0]*(?:на[\s\xa0]*Макавеите|Макаве[ий]ска)|Макавеи)|II(?:\.[\s\xa0]*Макавеи|[\s\xa0]*Макавеи)|2(?:\.[\s\xa0]*Макавеи|[\s\xa0]*Макавеи|Macc))
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["3Macc"]
		apocrypha: true
		regexp: ///(^|[^0-9A-Za-zªµºÀ-ÖØ-öø-ɏЀ-ҁ҃-҇Ҋ-ԧḀ-ỿⱠ-Ɀⷠ-ⷿꙀ-꙯ꙴ-꙽ꙿ-ꚗꚟꜢ-ꞈꞋ-ꞎꞐ-ꞓꞠ-Ɦꟸ-ꟿ])(
		(?:Трет(?:а[\s\xa0]*книга[\s\xa0]*Макаве[ий]ска|о[\s\xa0]*(?:книга[\s\xa0]*на[\s\xa0]*Макавеите|Макавеи))|III(?:\.[\s\xa0]*Макавеи|[\s\xa0]*Макавеи)|3(?:\.[\s\xa0]*Макавеи|[\s\xa0]*Макавеи|Macc))
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["4Macc"]
		apocrypha: true
		regexp: ///(^|[^0-9A-Za-zªµºÀ-ÖØ-öø-ɏЀ-ҁ҃-҇Ҋ-ԧḀ-ỿⱠ-Ɀⷠ-ⷿꙀ-꙯ꙴ-꙽ꙿ-ꚗꚟꜢ-ꞈꞋ-ꞎꞐ-ꞓꞠ-Ɦꟸ-ꟿ])(
		(?:Четвърта[\s\xa0]*(?:книга[\s\xa0]*на[\s\xa0]*Макавеите|Макавеи)|IV(?:\.[\s\xa0]*Макавеи|[\s\xa0]*Макавеи)|4(?:\.[\s\xa0]*Макавеи|[\s\xa0]*Макавеи|Macc))
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["1Macc"]
		apocrypha: true
		regexp: ///(^|[^0-9A-Za-zªµºÀ-ÖØ-öø-ɏЀ-ҁ҃-҇Ҋ-ԧḀ-ỿⱠ-Ɀⷠ-ⷿꙀ-꙯ꙴ-꙽ꙿ-ꚗꚟꜢ-ꞈꞋ-ꞎꞐ-ꞓꞠ-Ɦꟸ-ꟿ])(
		(?:Първа[\s\xa0]*(?:книга[\s\xa0]*(?:на[\s\xa0]*Макавеите|Макаве[ий]ска)|Макавеи)|I(?:\.[\s\xa0]*Макавеи|[\s\xa0]*Макавеи)|1(?:\.[\s\xa0]*Макавеи|[\s\xa0]*Макавеи|Macc))
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Ezek", "Ezra"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		Ез
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	,
		osis: ["Hab", "Obad"]
		regexp: ///(^|#{bcv_parser::regexps.pre_book})(
		Ав
			)(?:(?=[\d\s\xa0.:,;\x1e\x1f&\(\)（）\[\]/"'\*=~\-\u2013\u2014])|$)///gi
	]
	# Short-circuit the look if we know we want all the books.
	return books if include_apocrypha is true and case_sensitive is "none"
	# Filter out books in the Apocrypha if we don't want them. `Array.map` isn't supported below IE9.
	out = []
	for book in books
		continue if include_apocrypha is false and book.apocrypha? and book.apocrypha is true
		if case_sensitive is "books"
			book.regexp = new RegExp book.regexp.source, "g"
		out.push book
	out

# Default to not using the Apocrypha
bcv_parser::regexps.books = bcv_parser::regexps.get_books false, "none"