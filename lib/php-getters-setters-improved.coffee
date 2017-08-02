BaseCommand    = require './base-command'
PhpParser      = require './php-parser'
TemplateManager  = require './template-manager'
UIView       = require './ui.view'

module.exports =
  config:
    doNotTypeHint:
      type: 'array'
      default: ["mixed", "int", "integer", "double", "float", "number", "string", "boolean", "bool", "numeric", "unknown"]
      items:
        type: 'string'
    camelCasedMethodNames:
      type: 'boolean'
      title: 'Use CamelCased method names '
      default: true
    generateSettersFirst:
      type: 'boolean'
      title: 'Generate Setters first '
      default: false

  activate: (state) ->
    atom.commands.add 'atom-workspace',
    "php-getters-setters-improved:allGettersSetter": => @allGettersSetter()
    "php-getters-setters-improved:allGetters":     => @allGetters()
    "php-getters-setters-improved:allSetters":     => @allSetters()
    "php-getters-setters-improved:showUI":       => @showUI()
    "php-getters-setters-improved:newPropery":     => @showAddProperty()
    "php-getters-setters-improved:setterTemplateEditor":   => @showSetterTemplateEditor()
    "php-getters-setters-improved:getterTemplateEditor":   => @showGetterTemplateEditor()


  parse: ->
    ignoredTypeHints = atom.config.get 'php-getters-setters-improved.doNotTypeHint'
    bc   = new BaseCommand()
    parser = new PhpParser(ignoredTypeHints)

    parser.setContent(bc.getEditorContents())

    return {
      variables: parser.getVariables(ignoredTypeHints),
      functions: parser.getFunctions()
    }

  showAddProperty: ->
    editor = atom.workspace.getActiveTextEditor()

    unless editor.getGrammar().scopeName is 'text.html.php' or editor.getGrammar().scopeName is 'source.php'
      alert ('this is not a PHP file')
      return


    ui = new NewPropertyView(caller: @)

    atom.workspaceView.append(ui)

  showGetterTemplateEditor: ->
    atom.workspace.open(__dirname + '/../templates/getter')
  showSetterTemplateEditor: ->
    atom.workspace.open(__dirname +  '/../templates/setter')
  showUI: ->
    editor = atom.workspace.getActiveTextEditor()

    unless editor.getGrammar().scopeName is 'text.html.php' or editor.getGrammar().scopeName is 'source.php'
      alert ('this is not a PHP file')
      return

    data = @parse()
    variables = data.variables
    functions = data.functions

    ui = new UIView(variables: variables, caller: @)

    ui.show()

    # atom.views.getView(atom.workspace).append(ui)
  getVarsToProcess: (selectedVars, varsInClass) ->
    varsToProcess = []
    if selectedVars.length > 0
      for selectedVariable in selectedVars
        for tmpVar in varsInClass
          if tmpVar.name == selectedVariable.name
            varsToProcess.push tmpVar
    else
      varsToProcess = varsInClass

    console.log(varsToProcess)
    return varsToProcess

  allGettersSetter: (variables) ->
    editor = atom.workspace.getActiveTextEditor()
    unless editor.getGrammar().scopeName is 'text.html.php' or editor.getGrammar().scopeName is 'source.php'
      alert ('this is not a PHP file')
      return

    data = @parse()
    variables = @getVarsToProcess(variables || [], data.variables)
    functions = data.functions

    cw = new TemplateManager(functions)

    generateSettersFirst = atom.config.get 'php-getters-setters-improved.generateSettersFirst'

    code = ''
    if generateSettersFirst
      for variable in variables
        code += cw.writeSetter(variable)
        code += cw.writeGetter(variable)
    else
      for variable in variables
        code += cw.writeGetter(variable)
        code += cw.writeSetter(variable)
    bc = new BaseCommand()
    bc.writeAtEnd(code)

  allGetters: (variables) ->
    editor = atom.workspace.getActiveTextEditor()
    unless editor.getGrammar().scopeName is 'text.html.php' or editor.getGrammar().scopeName is 'source.php'
      alert ('this is not a PHP file')
      return

    data = @parse()

    variables = @getVarsToProcess(variables || [], data.variables)
    functions = data.functions

    cw = new TemplateManager(functions)

    code = ''
    for variable in variables
      code += cw.writeGetter(variable)

    bc = new BaseCommand()
    bc.writeAtEnd(code)

  allSetters: (variables) ->
    editor = atom.workspace.getActiveTextEditor()
    unless editor.getGrammar().scopeName is 'text.html.php' or editor.getGrammar().scopeName is 'source.php'
      alert ('this is not a PHP file')
      return

    data = @parse()
    variables = @getVarsToProcess(variables || [], data.variables)
    functions = data.functions

    cw = new TemplateManager(functions)

    code = ''
    for variable in variables
      code += cw.writeSetter(variable)

    bc = new BaseCommand()
    bc.writeAtEnd(code)
