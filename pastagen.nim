import macros, strutils, sequtils

type
    SubObj* = ref object
        old*: string
        before*: string
        after*: string
        new*: string
    Subs* = ref object
        substitutions*: seq[SubObj]
    Original* = ref object
        txt*: string

proc newOriginal*(txt = ""): Original =
  result = Original()
  result.txt = txt

proc newSubs*(): Subs =
  result = Subs()
  result.substitutions = @[]

proc newSubObj*(): SubObj =
  result = SubObj()

proc `$`*(s: SubObj): string =
    result = format("[old:$1,new:$2]", s.old, s.new)

template declareOriginal(): stmt {.immediate, dirty.} =
  when not declaredInScope(original):
    var original = newOriginal()

macro original*(body: stmt): stmt {.immediate.} =
  #echo(treeRepr(body))
  expectKind(body, nnkStmtList)

  result = newStmtList()

  let originalIdent = newIdentNode("vOriginal")
  result.add newVarStmt(originalIdent, newCall("newOriginal"))

  expectLen(body, 1)
  for txt in body.children:
    expectKind(txt, nnkTripleStrLit)
    let txtIdent = newIdentNode("txt")
    result.add newAssignment(newDotExpr(originalIdent, txtIdent), txt)
  #echo(treeRepr(result))

macro subs*(body: stmt): stmt {.immediate.} =
    #echo(treeRepr(body))
    expectKind(body, nnkStmtList)
    
    result = newStmtList()
    
    let subsIdent = newIdentNode("vSubs")
    let substitutionsIdent = newIdentNode("substitutions")
    let newSubstitutionIdent = newIdentNode("newSubstitution")
    let oldIdent = newIdentNode("old")
    let newIdent = newIdentNode("new")
    
    result.add newVarStmt(subsIdent, newCall("newSubs")) # vSubs = newSubs()
    result.add newVarStmt(newSubstitutionIdent, newCall("newSubObj")) # var newSubstitution
    let ass1 = newDotExpr(newSubstitutionIdent, oldIdent) # newSubstitution.old
    let ass2 = newDotExpr(newSubstitutionIdent, newIdent) # newSubstitution.new
    let ass3 = newDotExpr(subsIdent, substitutionsIdent) # vSubs.substitutions
    
    #echo(treeRepr(result))

    for mapping in body.children:
        expectLen(mapping, 3)
        expectKind(mapping[0], nnkIdent)
        expectKind(mapping[1], nnkStrLit)
        expectKind(mapping[2], nnkStrLit)
        result.add newAssignment(newSubstitutionIdent, newCall("newSubObj")) # newSubstitution = newSubObj()
        result.add newAssignment(ass1, mapping[1]) # newSubstitution.old = ""
        result.add newAssignment(ass2, mapping[2]) # newSubstitution.new = ""
        result.add newCall("add", ass3, newSubstitutionIdent) # add(vSubs.substitutions, newSubstitution)
    #result.add newCall("echo", ass3)
    #echo(treeRepr(result))

template declareOriginal(): stmt {.immediate, dirty.} =
    when not declaredInScope(vOriginal):
        var vOriginal = newOriginal()

template declareSubs(): stmt {.immediate, dirty.} =
    when not declaredInScope(vSubs):
        var vSubs = newSubs()

proc doSubsAndPrint(original: Original = newOriginal(), subs: Subs = newSubs()) =
    var newPasta: string = original.txt
    for sub in subs.substitutions:
        newPasta = newPasta.replaceWord(sub.old, sub.new)
    echo original.txt
    echo ""
    echo "------------------------------------"
    echo ""
    echo newPasta

template printMyPasta*(): stmt {.immediate.} =
    # vOriginal and vSubs are bound from outer scope
    # Declare our variables if they are not defined at outer scope
    declareOriginal()
    declareSubs()
    # Call working function
    doSubsAndPrint(vOriginal, vSubs)
