// eberban PEG grammar - v0.51
// =============================

// GRAMMAR
// main text rule
{
  var _g_foreign_quote_delim;

  function _join(arg) {
    if (typeof(arg) == "string")
      return arg;
    else if (arg) {
      var ret = "";
      for (var v in arg) { if (arg[v]) ret += _join(arg[v]); }
      return ret;
    }
  }

  function _node_empty(label, arg) {
    var ret = [];
    if (label) ret.push(label);
    if (arg && typeof arg == "object" && typeof arg[0] == "string" && arg[0]) {
      ret.push( arg );
      return ret;
    }
    if (!arg)
    {
      return ret;
    }
    return _node_int(label, arg);
  }

  function _node_int(label, arg) {
    if (typeof arg == "string")
      return arg;
    if (!arg) arg = [];
    var ret = [];
    if (label) ret.push(label);
    for (var v in arg) {
      if (arg[v] && arg[v].length != 0)
        ret.push( _node_int( null, arg[v] ) );
    }
    return ret;
  }

  function _node2(label, arg1, arg2) {
    return [label].concat(_node_empty(arg1)).concat(_node_empty(arg2));
  }

  function _node(label, arg) {
    var _n = _node_empty(label, arg);
    return (_n.length == 1 && label) ? [] : _n;
  }
  var _node_nonempty = _node;

  // === Functions for faking left recursion === //

  function _flatten_node(a) {
    // Flatten nameless nodes
    // e.g. [Name1, [[Name2, X], [Name3, Y]]] --> [Name1, [Name2, X], [Name3, Y]]
    if (is_array(a)) {
      var i = 0;
      while (i < a.length) {
        if (!is_array(a[i])) i++;
        else if (a[i].length === 0) // Removing []s
          a = a.slice(0, i).concat(a.slice(i + 1));
        else if (is_array(a[i][0]))
          a = a.slice(0, i).concat(a[i], a.slice(i + 1));
        else i++;
      }
    }
    return a;
  }

  function _group_leftwise(arr) {
    if (!is_array(arr)) return [];
    else if (arr.length <= 2) return arr;
    else return [_group_leftwise(arr.slice(0, -1)), arr[arr.length - 1]];
  }

  // "_lg" for "Leftwise Grouping".
  function _node_lg(label, arg) {
    return _node(label, _group_leftwise(_flatten_node(arg)));
  }

  function _node_lg2(label, arg) {
    if (is_array(arg) && arg.length == 2)
      arg = arg[0].concat(arg[1]);
    return _node(label, _group_leftwise(arg));
  }

  // === Foreign words functions === //

  function _assign_foreign_quote_delim(w) {
    if (is_array(w)) w = join_expr(w);
    else if (!is_string(w)) throw "ERROR: foreign_quote word is of type " + typeof w;
    w = w.toLowerCase().replace(/,/gm,"").replace(/h/g, "'");
    _g_foreign_quote_delim = w;
    return;
  }

  function _is_foreign_quote_delim(w) {
    if (is_array(w)) w = join_expr(w);
    else if (!is_string(w)) throw "ERROR: foreign_quote word is of type " + typeof w;
    /* Keeping spaces in the parse tree seems to result in the absorbtion of
       spaces into the closing delimiter candidate, so we'll remove any space
       character from our input. */
    w = w.replace(/[.\t\n\r?!\u0020]/g, "");
    w = w.toLowerCase().replace(/,/gm,"").replace(/h/g, "'");
    return w === _g_foreign_quote_delim;
  }

  function join_expr(n) {
    if (!is_array(n) || n.length < 1) return "";
    var s = "";
    var i = is_array(n[0]) ? 0 : 1;
    while (i < n.length) {
      s += is_string(n[i]) ? n[i] : join_expr(n[i]);
      i++;
    }
    return s;
  }

  function is_string(v) {
    // return $.type(v) === "string";
    return Object.prototype.toString.call(v) === '[object String]';
  }

  function is_array(v) {
    // return $.type(v) === "array";
    return Object.prototype.toString.call(v) === '[object Array]';
  }
}

text = expr:((free_interjection / free_parenthetical)* paragraphs? spaces? EOF?) {return _node("text", expr);}

// text structure
paragraphs = expr:(paragraph (&DU_clause paragraph)*) {return _node("paragraphs", expr);}
paragraph = expr:(DU_clause? paragraph_unit (&paragraph_unit_starter paragraph_unit)*) {return _node("paragraph", expr);}

paragraph_unit_starter = expr:(PA_clause / PO_clause / PU_clause) {return _node("paragraph_unit_starter", expr);}
paragraph_unit = expr:(paragraph_unit_erased / paragraph_unit_1) {return _node("paragraph_unit", expr);}
paragraph_unit_erased = expr:(paragraph_unit_1 CU_clause) {return _node("paragraph_unit_erased", expr);}
paragraph_unit_1 = expr:(definition / axiom / sentence) {return _node("paragraph_unit_1", expr);}

arguments_list = expr:((KI_clause / GI_clause)* BE_clause) {return _node("arguments_list", expr);}
defined = expr:(GI_clause / free_prefix* spaces? freeform_variable / predicate_compound / predicate_root) {return _node("defined", expr);}

definition = expr:(PO_clause defined scope) {return _node("definition", expr);}
sentence = expr:(PA_clause_elidible scope) {return _node("sentence", expr);}
axiom = expr:(PU_clause defined) {return _node("axiom", expr);}

// scope
scope = expr:(arguments_list? scope_1) {return _node("scope", expr);}

scope_1 = expr:(scope_sequence / scope_2) {return _node("scope_1", expr);}
scope_sequence = expr:((scope_sequence_item BU_clause)+ scope_sequence_item?) {return _node("scope_sequence", expr);}
scope_sequence_item = expr:(scope_2) {return _node("scope_sequence_item", expr);}

scope_2 = expr:(chaining) {return _node("scope_2", expr);}

// chaining and explicit switches
chaining = expr:((chaining_neg / chaining_unit)+) {return _node("chaining", expr);}
chaining_neg = expr:(BI_clause chaining) {return _node("chaining_neg", expr);}
chaining_unit = expr:(predicate vi_scope*) {return _node("chaining_unit", expr);}
vi_scope = expr:(vi_scope_first vi_scope_next* VEI_clause_elidible) {return _node("vi_scope", expr);}
vi_scope_first = expr:(BI_clause? VI_clause scope) {return _node("vi_scope_first", expr);}
vi_scope_next = expr:(BI_clause? FI_clause scope) {return _node("vi_scope_next", expr);}

// predicate unit
predicate = expr:(predicate_1 free_suffix*) {return _node("predicate", expr);}
predicate_1 = expr:((SI_clause !SI_clause / ZI_clause)* predicate_2) {return _node("predicate_1", expr);}
predicate_2 = expr:(BA_clause / MI_clause / predicate_quote / predicate_variable / predicate_scope / predicate_borrowing / predicate_root / predicate_number / predicate_compound) {return _node("predicate_2", expr);}

predicate_root = expr:(free_prefix* spaces? root_word) {return _node("predicate_root", expr);}
predicate_number = expr:(free_prefix* spaces? number) {return _node("predicate_number", expr);}
predicate_compound = expr:(free_prefix* spaces? compound) {return _node("predicate_compound", expr);}
predicate_borrowing = expr:(free_prefix* borrowing_group) {return _node("predicate_borrowing", expr);}
predicate_scope = expr:(PE_clause scope PEI_clause_elidible) {return _node("predicate_scope", expr);}

// quotes
predicate_quote = expr:(grammatical_quote / one_word_quote / foreign_quote) {return _node("predicate_quote", expr);}
grammatical_quote = expr:(CA_clause text CAI_clause) {return _node("grammatical_quote", expr);}
one_word_quote = expr:(CE_clause spaces? (native_word / compound / borrowing)) {return _node("one_word_quote", expr);}

foreign_quote = expr:(COI_clause / foreign_quote_1) {return _node("foreign_quote", expr);}
foreign_quote_1 = expr:(CO_clause spaces? foreign_quote_open pause_char foreign_quote_content single_pause_char foreign_quote_close) {return _node("foreign_quote_1", expr);}

foreign_quote_content = expr:((!(single_pause_char foreign_quote_close) .)*) { return ["foreign_quote_content", _join(expr)]; }
foreign_quote_open = expr:(native_form ) { _assign_foreign_quote_delim(expr); return _node("foreign_quote_open", expr); }// doesn't perform &post_word check
foreign_quote_word = expr:((!single_pause_char .)+) {return _node("foreign_quote_word", expr);}
foreign_quote_close = expr:(native_word ) &{ return _is_foreign_quote_delim(expr); } { return _node("foreign_quote_close", expr); }// performs &post_word check

// numbers
number = expr:(number_base? (number_1 number_fractional? / number_1? number_fractional) number_magnitude? JI_clause?) {return _node("number", expr);}
number_1 = expr:(TI_clause+) {return _node("number_1", expr);}
number_base = expr:(TI_clause JU_clause) {return _node("number_base", expr);}
number_fractional = expr:(JO_clause number_1? number_repeat? !number_fractional_constraint) {return _node("number_fractional", expr);}
// Having a fractional part prevents to use anything but "ji"
number_fractional_constraint = expr:(number_magnitude? spaces? j i (h / ieaou)) {return _node("number_fractional_constraint", expr);}
number_repeat = expr:(JA_clause number_1) {return _node("number_repeat", expr);}
number_magnitude = expr:(JE_clause number_1) {return _node("number_magnitude", expr);}

// borrowings
borrowing_group = expr:((spaces? borrowing)+ BE_clause_elidible) {return _node("borrowing_group", expr);}

// variables
predicate_variable = expr:(free_prefix* BO_clause? (KI_clause / defined)) {return _node("predicate_variable", expr);}

// free affixes
free_prefix = expr:(free_metadata) {return _node("free_prefix", expr);}
free_metadata = expr:(DI_clause) {return _node("free_metadata", expr);}

free_suffix = expr:(free_parenthetical / free_interjection) {return _node("free_suffix", expr);}
free_interjection = expr:(DE_clause predicate_1) {return _node("free_interjection", expr);} // avoid nested free suffix
free_parenthetical = expr:(DA_clause text DAI_clause) {return _node("free_parenthetical", expr);}

// PARTICLES CLAUSES
BI_clause = expr:(free_prefix* spaces? BI free_suffix*) {return _node("BI_clause", expr);} // wide-scope negation
BE_clause = expr:(spaces? BE) {return _node("BE_clause", expr);} // miscellaneous terminator
BA_clause = expr:(free_prefix* spaces? BA) {return _node("BA_clause", expr);} // inline argument
BO_clause = expr:(free_prefix* spaces? BO) {return _node("BO_clause", expr);} // variable assignement
BU_clause = expr:(free_prefix* spaces? BU) {return _node("BU_clause", expr);} // sequence separator
 //
DI_clause = expr:(spaces? DI) {return _node("DI_clause", expr);} // free metadata
DE_clause = expr:(spaces? DE) {return _node("DE_clause", expr);} // free interjection
DA_clause = expr:(spaces? DA) {return _node("DA_clause", expr);} // free parenthetical starter
DAI_clause = expr:(spaces? DAI) {return _node("DAI_clause", expr);} // free parenthetical terminator
DU_clause = expr:(spaces? DU) {return _node("DU_clause", expr);} // paragraph marker
 //
SI_clause = expr:(free_prefix* spaces? SI) {return _node("SI_clause", expr);} // chaining modification
ZI_clause = expr:(free_prefix* spaces? ZI) {return _node("ZI_clause", expr);} // predicate transformation
VI_clause = expr:(free_prefix* spaces? VI free_suffix*) {return _node("VI_clause", expr);} // explicit bind + VI-scope
FI_clause = expr:(free_prefix* spaces? FI free_suffix*) {return _node("FI_clause", expr);} // next explicit bind
VEI_clause = expr:(spaces? VEI) {return _node("VEI_clause", expr);} // VI-scope terminator
 //
GI_clause = expr:(spaces? GI) {return _node("GI_clause", expr);} // predicate variables
KI_clause = expr:(spaces? KI) {return _node("KI_clause", expr);} // symbol/generic variables
MI_clause = expr:(free_prefix* spaces? MI) {return _node("MI_clause", expr);} // particle predicates
 //
PE_clause = expr:(free_prefix* spaces? PE free_suffix*) {return _node("PE_clause", expr);} // predicate scope starter
PEI_clause = expr:(spaces? PEI) {return _node("PEI_clause", expr);} // predicate scope elidible terminator
PA_clause = expr:(free_prefix* spaces? PA free_suffix*) {return _node("PA_clause", expr);} // sentence starter
PO_clause = expr:(free_prefix* spaces? PO free_suffix*) {return _node("PO_clause", expr);} // definition starter
PU_clause = expr:(spaces? PU) {return _node("PU_clause", expr);} // axiom toggle
 //
TI_clause = expr:(spaces? TI) {return _node("TI_clause", expr);} // digits
 //
JI_clause = expr:(spaces? JI) {return _node("JI_clause", expr);} // number terminator
JE_clause = expr:(spaces? JE) {return _node("JE_clause", expr);} // number magnitude separator
JA_clause = expr:(spaces? JA) {return _node("JA_clause", expr);} // number repeating part separator
JO_clause = expr:(spaces? JO) {return _node("JO_clause", expr);} // number decimal separator
JU_clause = expr:(spaces? JU) {return _node("JU_clause", expr);} // number base separator
 //
CA_clause = expr:(free_prefix* spaces? CA) {return _node("CA_clause", expr);} // grammatical quote starter
CAI_clause = expr:(free_prefix* spaces? CAI) {return _node("CAI_clause", expr);} // grammatical quote terminator
CE_clause = expr:(free_prefix* spaces? CE) {return _node("CE_clause", expr);} // one word quote
CO_clause = expr:(free_prefix* spaces? CO) {return _node("CO_clause", expr);} // foreign quote
COI_clause = expr:(free_prefix* spaces? COI) {return _node("COI_clause", expr);} // skipped foreign quote
 //
CU_clause = expr:(spaces? CU) {return _node("CU_clause", expr);} // paragraph unit eraser

BE_clause_elidible = expr:(BE_clause?) {return (expr == "" || !expr) ? ["BE"] : _node_empty("BE_clause_elidible", expr);}
PA_clause_elidible = expr:(PA_clause?) {return (expr == "" || !expr) ? ["PA"] : _node_empty("PA_clause_elidible", expr);}
PEI_clause_elidible = expr:(PEI_clause?) {return (expr == "" || !expr) ? ["PEI"] : _node_empty("PEI_clause_elidible", expr);}
VEI_clause_elidible = expr:(VEI_clause?) {return (expr == "" || !expr) ? ["VEI"] : _node_empty("VEI_clause_elidible", expr);}

// PARTICLE FAMILIES
BI = expr:(&particle_word (b &i hieaou) &post_word) {return _node("BI", expr);}
BE = expr:(&particle_word (b &e hieaou) &post_word) {return _node("BE", expr);}
BA = expr:(&particle_word (b &a hieaou) &post_word) {return _node("BA", expr);}
BO = expr:(&particle_word (b &o hieaou) &post_word) {return _node("BO", expr);}
BU = expr:(&particle_word (b &u hieaou) &post_word) {return _node("BU", expr);}
CE = expr:(&particle_word (c &e hieaou) &post_word) {return _node("CE", expr);}
CA = expr:(&particle_word !(CAI &post_word) (c &a hieaou) &post_word) {return _node("CA", expr);}
CAI = expr:(&particle_word (c a i) &post_word) {return _node("CAI", expr);}
CO = expr:(&particle_word !(COI &post_word) (c &o hieaou) &post_word) {return _node("CO", expr);}
COI = expr:(&particle_word (c o i) &post_word) {return _node("COI", expr);}
CU = expr:(&particle_word (c &u hieaou) &post_word) {return _node("CU", expr);}
DI = expr:(&particle_word (d &i hieaou) &post_word) {return _node("DI", expr);}
DE = expr:(&particle_word (d &e hieaou) &post_word) {return _node("DE", expr);}
DA = expr:(&particle_word !(DAI &post_word) (d &a hieaou) &post_word) {return _node("DA", expr);}
DAI = expr:(&particle_word (d a i) &post_word) {return _node("DAI", expr);}
DU = expr:(&particle_word (d &u hieaou) &post_word) {return _node("DU", expr);}
FI = expr:(&particle_word (f hieaou) &post_word) {return _node("FI", expr);}
GI = expr:(&particle_word (g hieaou) &post_word) {return _node("GI", expr);}
JI = expr:(&particle_word (j &i hieaou) &post_word) {return _node("JI", expr);}
JE = expr:(&particle_word (j &e hieaou) &post_word) {return _node("JE", expr);}
JA = expr:(&particle_word (j &a hieaou) &post_word) {return _node("JA", expr);}
JO = expr:(&particle_word (j &o hieaou) &post_word) {return _node("JO", expr);}
JU = expr:(&particle_word (j &u hieaou) &post_word) {return _node("JU", expr);}
KI = expr:(&particle_word (k hieaou) &post_word) {return _node("KI", expr);}
MI = expr:(&particle_word ((m / x) hieaou) &post_word) {return _node("MI", expr);}
PI = expr:(&particle_word (p &i hieaou) &post_word) {return _node("PI", expr);}
PE = expr:(&particle_word (p &e hieaou) &post_word) {return _node("PE", expr);}
PEI = expr:(&particle_word (p e i) &post_word) {return _node("PEI", expr);}
PA = expr:(&particle_word (p &a hieaou) &post_word) {return _node("PA", expr);}
PO = expr:(&particle_word (p &o hieaou) &post_word) {return _node("PO", expr);}
PU = expr:(&particle_word (p &u hieaou) &post_word) {return _node("PU", expr);}
SI = expr:(&particle_word (s hieaou) &post_word) {return _node("SI", expr);}
TI = expr:(&particle_word (t hieaou / digit) &post_word) {return _node("TI", expr);}
VI = expr:(&particle_word !(VEI &post_word) (v hieaou) &post_word) {return _node("VI", expr);}
VEI = expr:(&particle_word (v e i) &post_word) {return _node("VEI", expr);}
ZI = expr:(&particle_word (z hieaou) &post_word) {return _node("ZI", expr);}


// - Compounds
compound = expr:((compound_2 / compound_3 / compound_n)) {return _node("compound", expr);}
compound_2 = expr:(e i? compound_word compound_word) {return _node("compound_2", expr);}
compound_3 = expr:(a i? compound_word compound_word compound_word) {return _node("compound_3", expr);}
compound_n = expr:(o i? (!compound_n_end compound_word)+ compound_n_end) {return _node("compound_n", expr);}
compound_n_end = expr:(spaces o spaces) {return _node("compound_n_end", expr);}
compound_word = expr:(spaces? (borrowing / native_word)) {return _node("compound_word", expr);}

// - Free-form words
freeform_variable = expr:(i (spaces &i / hyphen !i) freeform_content freeform_end) {return _node("freeform_variable", expr);}
borrowing = expr:(u (spaces &u / hyphen !u) freeform_content freeform_end) {return _node("borrowing", expr);}
freeform_content = expr:(freeform_initial? hieaou (consonant_triplet hieaou)* consonant?) {return _node("freeform_content", expr);}
freeform_initial = expr:(consonant_triplet / medial_pair / initial_pair / consonant / h) {return _node("freeform_initial", expr);}
freeform_end = expr:((single_pause_char / space_char / EOF)) {return _node("freeform_end", expr);}

// - Native words
native_word = expr:(root_word / particle_word) {return _node("native_word", expr);}
native_form = expr:(root_form / particle_form) {return _node("native_form", expr);}

particle_word = expr:(particle_form &post_word) {return _node("particle_word", expr);}
particle_form = expr:(!sonorant consonant hieaou !medial_pair) {return _node("particle_form", expr);}

root_word = expr:(root_form &post_word) {return _node("root_word", expr);}
root_form = expr:(!sonorant (root_form_1 / root_form_2 / root_form_3)) {return _node("root_form", expr);}
root_form_1 = expr:(consonant hieaou ((medial_pair / hyphen sonorant) hieaou)+ sonorant?) {return _node("root_form_1", expr);}
root_form_2 = expr:(consonant hieaou sonorant) {return _node("root_form_2", expr);}
root_form_3 = expr:(initial_pair hieaou ((medial_pair / hyphen sonorant) hieaou)* sonorant?) {return _node("root_form_3", expr);}

// - Legal clusters
hieaou = expr:(ieaou (hyphen h ieaou)*) {return _node("hieaou", expr);}
ieaou = expr:(vowel (hyphen vowel)*) {return _node("ieaou", expr);}

consonant_triplet = expr:((consonant_triplet_1 / consonant_triplet_2) !consonant) {return _node("consonant_triplet", expr);}
consonant_triplet_1 = expr:(&medial_pair !sonorant consonant hyphen initial_pair) {return _node("consonant_triplet_1", expr);}
consonant_triplet_2 = expr:(medial_pair / sonorant? hyphen (initial_pair / !sonorant consonant) / sonorant hyphen) {return _node("consonant_triplet_2", expr);}

medial_pair = expr:(!initial medial_patterns) {return _node("medial_pair", expr);}
medial_patterns = expr:((medial_n / medial_fv / medial_plosive)) {return _node("medial_patterns", expr);}
medial_n = expr:((m / liquid) hyphen n / n hyphen liquid) {return _node("medial_n", expr);}
medial_fv = expr:((f / v) hyphen (plosive / sibilant / m)) {return _node("medial_fv", expr);}
medial_plosive = expr:(plosive hyphen (f / v / plosive / m)) {return _node("medial_plosive", expr);}

// initial pairs cannot contain an hyphen
initial_pair = expr:(&initial consonant consonant !consonant) {return _node("initial_pair", expr);}
// we need to support hyphenation to use `!initial` in `medial_pair`
initial = expr:(((plosive / f / v) hyphen sibilant / sibilant hyphen other / sibilant hyphen sonorant / other hyphen sonorant)) {return _node("initial", expr);}

other = expr:((p / b) !n / (t / d) !n !l / v / f / k / g / m / n !liquid) {return _node("other", expr);}
plosive = expr:(t / d / k / g / p / b) {return _node("plosive", expr);}
sibilant = expr:(c / s / j / z) {return _node("sibilant", expr);}
sonorant = expr:(n / r / l) {return _node("sonorant", expr);}

consonant = expr:((voiced / unvoiced / liquid / nasal)) {return _node("consonant", expr);}
nasal = expr:(m / n / x) {return _node("nasal", expr);}
liquid = expr:(l / r) {return _node("liquid", expr);}
voiced = expr:(b / d / g / v / z / j) {return _node("voiced", expr);}
unvoiced = expr:(p / t / k / f / s / c) {return _node("unvoiced", expr);}

vowel = expr:(i / e / a / o / u) {return _node("vowel", expr);}

// Legal letters
i = expr:([iI]+) {return ["i", "i"];} // <LEAF>
e = expr:([eE]+) {return ["e", "e"];} // <LEAF>
a = expr:([aA]+) {return ["a", "a"];} // <LEAF>
o = expr:([oO]+) {return ["o", "o"];} // <LEAF>
u = expr:([uU]+) {return ["u", "u"];} // <LEAF>

h = expr:([hH]+) {return ["h", "h"];} // <LEAF>
n = expr:([nN]+) {return ["n", "n"];} // <LEAF>
r = expr:([rR]+) {return ["r", "r"];} // <LEAF>
l = expr:([lL]+) {return ["l", "l"];} // <LEAF>

m = expr:([mM]+) {return ["m", "m"];} // <LEAF>
p = expr:([pP]+ !voiced) {return ["p", "p"];} // <LEAF>
b = expr:([bB]+ !unvoiced) {return ["b", "b"];} // <LEAF>
f = expr:([fF]+ !voiced) {return ["f", "f"];} // <LEAF>
v = expr:([vV]+ !unvoiced) {return ["v", "v"];} // <LEAF>
t = expr:([tT]+ !voiced) {return ["t", "t"];} // <LEAF>
d = expr:([dD]+ !unvoiced) {return ["d", "d"];} // <LEAF>
s = expr:([sS]+ !c !voiced) {return ["s", "s"];} // <LEAF>
z = expr:([zZ]+ !j !unvoiced) {return ["z", "z"];} // <LEAF>
c = expr:([cC]+ !s !voiced) {return ["c", "c"];} // <LEAF>
j = expr:([jJ]+ !z !unvoiced) {return ["j", "j"];} // <LEAF>
g = expr:([gG]+ !unvoiced) {return ["g", "g"];} // <LEAF>
k = expr:([kK]+ !voiced) {return ["k", "k"];} // <LEAF>

x = expr:([xX]+ !voiced) {return ["x", "x"];} // <LEAF>

// - Spaces / Pause
post_word = expr:((single_pause_char &vowel) / !sonorant &consonant / spaces) {return _node("post_word", expr);}
spaces = expr:(space_char+ hesitation? (single_pause_char &vowel)? / single_pause_char &vowel / EOF) {return _node("spaces", expr);}
hesitation = expr:((n (space_char+ / EOF))+) {return _node("hesitation", expr);}

// - Special characters
hyphen = expr:((hyphen_char [\n\r]*)?) {return _node("hyphen", expr);} // hyphens + line break support
hyphen_char = expr:([\u2010\u2014\u002D]) {return _node("hyphen_char", expr);}
single_pause_char = expr:(pause_char !pause_char) {return _node("single_pause_char", expr);}
pause_char = expr:((['’`])) {return _node("pause_char", expr);}
space_char = expr:(!(single_pause_char / digit / hyphen_char / [a-zA-Z]) .) {return _join(expr);}
digit = expr:([0-9]) {return ["digit", expr];} // <LEAF2>
EOF = expr:(!.) {return _node("EOF", expr);}
