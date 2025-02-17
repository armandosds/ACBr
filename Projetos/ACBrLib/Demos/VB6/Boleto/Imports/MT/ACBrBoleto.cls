VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
  Persistable = 0  'NotPersistable
  DataBindingBehavior = 0  'vbNone
  DataSourceBehavior  = 0  'vbNone
  MTSTransactionMode  = 0  'NotAnMTSObject
END
Attribute VB_Name = "ACBrBoleto"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = True
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Explicit

Private libHandler As Long

Const BUFFER_LENGTH As Long = 1024
                                
Private Declare Function Boleto_Inicializar _
                Lib "ACBrBoleto32.dll" (ByRef libHandler As Long, _
                                        ByVal eArqConfig As String, _
                                        ByVal eChaveCrypt As String) As Long
                   
Private Declare Function Boleto_Finalizar Lib "ACBrBoleto32.dll" (ByVal libHandler As Long) As Long

Private Declare Function Boleto_Nome _
                Lib "ACBrBoleto32.dll" (ByVal libHandler As Long, _
                                        ByVal buffer As String, _
                                        ByRef bufferLen As Long) As Long
                   
Private Declare Function Boleto_Versao _
                Lib "ACBrBoleto32.dll" (ByVal libHandler As Long, _
                                        ByVal buffer As String, _
                                        ByRef bufferLen As Long) As Long

Private Declare Function Boleto_UltimoRetorno _
                Lib "ACBrBoleto32.dll" (ByVal libHandler As Long, _
                                        ByVal buffer As String, _
                                        ByRef bufferLen As Long) As Long
                                        
Private Declare Function Boleto_ConfigImportar _
                Lib "ACBrBoleto32.dll" (ByVal libHandler As Long, _
                                        ByVal eArqConfig As String) As Long
                   
Private Declare Function Boleto_ConfigExportar _
                Lib "ACBrBoleto32.dll" (ByVal libHandler As Long, _
                                        ByVal buffer As String, _
                                        ByRef bufferLen As Long) As Long
                                        
Private Declare Function Boleto_ConfigLer _
                Lib "ACBrBoleto32.dll" (ByVal libHandler As Long, _
                                        ByVal eArqConfig As String) As Long

Private Declare Function Boleto_ConfigGravar _
                Lib "ACBrBoleto32.dll" (ByVal libHandler As Long, _
                                        ByVal eArqConfig As String) As Long
                   
Private Declare Function Boleto_ConfigLerValor _
                Lib "ACBrBoleto32.dll" (ByVal libHandler As Long, _
                                        ByVal eSessao As String, _
                                        ByVal eChave As String, _
                                        ByVal buffer As String, _
                                        ByRef bufferLen As Long) As Long

Private Declare Function Boleto_ConfigGravarValor _
                Lib "ACBrBoleto32.dll" (ByVal libHandler As Long, _
                                        ByVal eSessao As String, _
                                        ByVal eChave As String, _
                                        ByVal valor As String) As Long
                                            
Private Declare Function Boleto_ConfigurarDados _
                Lib "ACBrBoleto32.dll" (ByVal libHandler As Long, _
                                        ByVal eArquivoIni As String) As Long
                                     
Private Declare Function Boleto_IncluirTitulos _
                Lib "ACBrBoleto32.dll" (ByVal libHandler As Long, _
                                        ByVal eArquivoIni As String, _
                                        ByVal eTpSaida As String) As Long
                                     
Private Declare Function Boleto_LimparLista Lib "ACBrBoleto32.dll" (ByVal libHandler As Long) As Long
                
Private Declare Function Boleto_TotalTitulosLista _
                Lib "ACBrBoleto32.dll" (ByVal libHandler As Long) As Long
                                     
Private Declare Function Boleto_Imprimir _
                Lib "ACBrBoleto32.dll" (ByVal libHandler As Long, _
                                        ByVal eNomeImpressora As String) As Long
                
Private Declare Function Boleto_ImprimirBoleto _
                Lib "ACBrBoleto32.dll" (ByVal libHandler As Long, _
                                        ByVal eIndice As Long, _
                                        ByVal eNomeImpressora As String) As Long
                
Private Declare Function Boleto_GerarPDF Lib "ACBrBoleto32.dll" (ByVal libHandler As Long) As Long

Private Declare Function Boleto_GerarHTML Lib "ACBrBoleto32.dll" (ByVal libHandler As Long) As Long

Private Declare Function Boleto_GerarRemessa _
                Lib "ACBrBoleto32.dll" (ByVal libHandler As Long, _
                                        ByVal eDir As String, _
                                        ByVal eNumArquivo As Long, _
                                        ByVal eNomeArquivo As String) As Long
                                     
Private Declare Function Boleto_LerRetorno _
                Lib "ACBrBoleto32.dll" (ByVal libHandler As Long, _
                                        ByVal eDir As String, _
                                        ByVal eNomeArq As String) As Long
                                        
Private Declare Function Boleto_ObterRetorno _
                Lib "ACBrBoleto32.dll" (ByVal libHandler As Long, _
                                        ByVal eDir As String, _
                                        ByVal eNomeArq As String, _
                                        ByVal buffer As String, _
                                        ByRef bufferLen As Long) As Long
                                     
Private Declare Function Boleto_EnviarEmail _
                Lib "ACBrBoleto32.dll" (ByVal libHandler As Long, _
                                        ByVal ePara As String, _
                                        ByVal eAssunto As String, _
                                        ByVal eMensagem As String, _
                                        ByVal eCC As String) As Long
                                        
Private Declare Function Boleto_EnviarEmailBoleto _
                Lib "ACBrBoleto32.dll" (ByVal libHandler As Long, _
                                        ByVal eIndice As Long, _
                                        ByVal ePara As String, _
                                        ByVal eAssunto As String, _
                                        ByVal eMensagem As String, _
                                        ByVal eCC As String) As Long
                                     
Private Declare Function Boleto_SetDiretorioArquivo _
                Lib "ACBrBoleto32.dll" (ByVal libHandler As Long, _
                                        ByVal eDir As String, _
                                        ByVal eArq As String) As Long
                                     
Private Declare Function Boleto_ListaBancos _
                Lib "ACBrBoleto32.dll" (ByVal libHandler As Long, _
                                        ByVal buffer As String, _
                                        ByRef bufferLen As Long) As Long
                                     
Private Declare Function Boleto_ListaCaractTitulo _
                Lib "ACBrBoleto32.dll" (ByVal libHandler As Long, _
                                        ByVal buffer As String, _
                                        ByRef bufferLen As Long) As Long
                                     
Private Declare Function Boleto_ListaOcorrencias _
                Lib "ACBrBoleto32.dll" (ByVal libHandler As Long, _
                                        ByVal buffer As String, _
                                        ByRef bufferLen As Long) As Long
                                     
Private Declare Function Boleto_ListaOcorrenciasEX _
                Lib "ACBrBoleto32.dll" (ByVal libHandler As Long, _
                                        ByVal buffer As String, _
                                        ByRef bufferLen As Long) As Long
                                     
Private Declare Function Boleto_TamNossoNumero _
                Lib "ACBrBoleto32.dll" (ByVal libHandler As Long, _
                                        ByVal eCarteira As String, _
                                        ByVal enossoNumero As String, _
                                        ByVal eConvenio As String) As Long
                                     
Private Declare Function Boleto_CodigosMoraAceitos _
                Lib "ACBrBoleto32.dll" (ByVal libHandler As Long, _
                                        ByVal buffer As String, _
                                        ByRef bufferLen As Long) As Long
                                     
Private Declare Function Boleto_SelecionaBanco _
                Lib "ACBrBoleto32.dll" (ByVal libHandler As Long, _
                                        ByVal eCodBanco As String) As Long
                                     
Private Declare Function Boleto_MontarNossoNumero _
                Lib "ACBrBoleto32.dll" (ByVal libHandler As Long, _
                                        ByVal eIndice As Long, _
                                        ByVal buffer As String, _
                                        ByRef bufferLen As Long) As Long
                                     
Private Declare Function Boleto_RetornaLinhaDigitavel _
                Lib "ACBrBoleto32.dll" (ByVal libHandler As Long, _
                                        ByVal eIndice As Long, _
                                        ByVal buffer As String, _
                                        ByRef bufferLen As Long) As Long
                                     
Private Declare Function Boleto_RetornaCodigoBarras _
                Lib "ACBrBoleto32.dll" (ByVal libHandler As Long, _
                                        ByVal eIndice As Long, _
                                        ByVal buffer As String, _
                                        ByRef bufferLen As Long) As Long
                                     
Public Sub InicializarLib(Optional ByVal eArqConfig As String = "", _
                          Optional ByVal eChaveCrypt As String = "")

    SetLibPath

    Dim retorno As Long

    retorno = Boleto_Inicializar(libHandler, eArqConfig, eChaveCrypt)
    CheckResult retorno
End Sub

Public Sub FinalizarLib()

    Dim retorno As Long

    retorno = Boleto_Finalizar(libHandler)
    CheckResult retorno
End Sub

Public Sub ConfigImportar(ByVal eArqConfig As String)

    Dim retorno As Long

    retorno = Boleto_ConfigImportar(libHandler, eArqConfig)
    CheckResult (retorno)
    
End Sub
    
Public Function ConfigExportar() As String

    Dim retorno   As Long
    Dim buffer    As String
    Dim bufferLen As Long

    bufferLen = BUFFER_LENGTH
    
    buffer = String$(bufferLen, " ")
    
    retorno = Boleto_ConfigExportar(libHandler, buffer, bufferLen)
    CheckResult retorno
    
    ConfigExportar = processResult(buffer, bufferLen)
    
End Function

Public Sub ConfigLer(Optional eArqConfig As String = "")

    Dim retorno As Long

    retorno = Boleto_ConfigLer(libHandler, eArqConfig)
    CheckResult retorno
End Sub

Public Sub ConfigGravar(Optional eArqConfig As String = "")

    Dim retorno As Long

    retorno = Boleto_ConfigGravar(libHandler, eArqConfig)
    CheckResult retorno
End Sub

Public Function ConfigLerValor(ByVal eSessao As String, ByVal eChave As String) As String

    Dim retorno   As Long
    Dim buffer    As String
    Dim bufferLen As Long

    bufferLen = BUFFER_LENGTH
    buffer = String$(bufferLen, " ")
    
    retorno = Boleto_ConfigLerValor(libHandler, eSessao, eChave, buffer, bufferLen)
    CheckResult retorno
    
    ConfigLerValor = processResult(buffer, bufferLen)
End Function

Public Sub ConfigGravarValor(ByVal eSessao As String, _
                             ByVal eChave As String, _
                             ByVal valor As String)

    Dim retorno As Long
    
    retorno = Boleto_ConfigGravarValor(libHandler, eSessao, eChave, valor)
    CheckResult retorno
End Sub

Public Function Nome() As String

    Dim retorno   As Long
    Dim buffer    As String
    Dim bufferLen As Long

    bufferLen = BUFFER_LENGTH
    buffer = String$(bufferLen, " ")
        
    retorno = Boleto_Nome(libHandler, buffer, bufferLen)
    CheckResult retorno
    
    Nome = processResult(buffer, bufferLen)
End Function

Public Function Versao() As String

    Dim retorno   As Long
    Dim buffer    As String
    Dim bufferLen As Long

    bufferLen = BUFFER_LENGTH
    
    buffer = String$(bufferLen, " ")
    
    retorno = Boleto_Versao(libHandler, buffer, bufferLen)
    CheckResult retorno
    
    Versao = processResult(buffer, bufferLen)
End Function

Public Sub ConfigurarDados(ByVal eArquivoIni As String)
    Dim retorno   As Long
    
    retorno = Boleto_ConfigurarDados(libHandler, eArquivoIni)
    CheckResult retorno
End Sub

Public Sub IncluirTitulos(ByVal eArquivoIni As String, Optional ByVal eTpSaida As String = "")
    Dim retorno   As Long
    
    retorno = Boleto_IncluirTitulos(libHandler, eArquivoIni, eTpSaida)
    CheckResult retorno
End Sub

Public Sub LimparLista()
    Dim retorno   As Long
    
    retorno = Boleto_LimparLista(libHandler)
    CheckResult retorno
End Sub

Public Function TotalTitulosLista() As Long
    Dim retorno   As Long
    
    retorno = Boleto_TotalTitulosLista(libHandler)
    CheckResult retorno
    
    TotalTitulosLista = retorno
End Function

Public Sub Imprimir(Optional ByVal eNomeImpressora As String = "")
    Dim retorno   As Long
    
    retorno = Boleto_Imprimir(libHandler, eNomeImpressora)
    CheckResult retorno
End Sub

Public Sub ImprimirBoleto(ByVal Indice As Long, Optional ByVal eNomeImpressora As String = "")
    Dim retorno   As Long
    
    retorno = Boleto_ImprimirBoleto(libHandler, Indice, eNomeImpressora)
    CheckResult retorno
End Sub

Public Sub GerarPDF()
    Dim retorno   As Long
    
    retorno = Boleto_GerarPDF(libHandler)
    CheckResult retorno
End Sub

Public Sub GerarHTML()
    Dim retorno   As Long
    
    retorno = Boleto_GerarHTML(libHandler)
    CheckResult retorno
End Sub

Public Sub GerarRemessa(ByVal eDir As String, ByVal eNumArquivo As Long, ByVal eNomeArquivo As String)
    Dim retorno   As Long
    
    retorno = Boleto_GerarRemessa(libHandler, eDir, eNumArquivo, eNomeArquivo)
    CheckResult retorno
End Sub

Public Sub EnviarEmail(ByVal ePara As String, ByVal eAssunto As String, ByVal eMensagem As String, ByVal eCC As String)
    Dim retorno   As Long
    
    retorno = Boleto_EnviarEmail(libHandler, ePara, eAssunto, eMensagem, eCC)
    CheckResult retorno
End Sub

Public Sub EnviarEmailBoleto(ByVal eIndice As Long, ByVal ePara As String, ByVal eAssunto As String, ByVal eMensagem As String, ByVal eCC As String)
    Dim retorno As Long
    
    retorno = Boleto_EnviarEmailBoleto(libHandler, eIndice, ePara, eAssunto, eMensagem, eCC)
    CheckResult retorno
End Sub

Public Sub LerRetorno(ByVal eDir As String, ByVal eNomeArquivo As String)
    Dim retorno   As Long
    
    retorno = Boleto_LerRetorno(libHandler, eDir, eNomeArquivo)
    CheckResult retorno
End Sub

Public Function ObterRetorno(ByVal eDir As String, ByVal eNomeArquivo As String) As String
    Dim retorno   As Long
    Dim buffer    As String
    Dim bufferLen As Long

    bufferLen = BUFFER_LENGTH
    buffer = String$(bufferLen, " ")
    
    retorno = Boleto_ObterRetorno(libHandler, eDir, eNomeArquivo, buffer, bufferLen)
    CheckResult retorno
    
    ObterRetorno = processResult(buffer, bufferLen)
End Function

Public Sub SetDiretorioArquivo(ByVal eDir As String, ByVal eArq As String)
    Dim retorno   As Long
    
    retorno = Boleto_SetDiretorioArquivo(libHandler, eDir, eArq)
    CheckResult retorno
End Sub

Public Function ListaBancos() As String()
    Dim retorno   As Long
    Dim buffer    As String
    Dim bufferLen As Long

    bufferLen = BUFFER_LENGTH
    buffer = String$(bufferLen, " ")
    
    retorno = Boleto_ListaBancos(libHandler, buffer, bufferLen)
    CheckResult retorno
    
    ListaBancos = Split(processResult(buffer, bufferLen), "|")
End Function

Public Function ListaCaractTitulo() As String()
    Dim retorno   As Long
    Dim buffer    As String
    Dim bufferLen As Long

    bufferLen = BUFFER_LENGTH
    buffer = String$(bufferLen, " ")
    
    retorno = Boleto_ListaCaractTitulo(libHandler, buffer, bufferLen)
    CheckResult retorno
    
    ListaCaractTitulo = Split(processResult(buffer, bufferLen), "|")
End Function

Public Function ListaOcorrencias() As String()
    Dim retorno   As Long
    Dim buffer    As String
    Dim bufferLen As Long

    bufferLen = BUFFER_LENGTH
    buffer = String$(bufferLen, " ")
    
    retorno = Boleto_ListaOcorrencias(libHandler, buffer, bufferLen)
    CheckResult retorno
    
    ListaOcorrencias = Split(processResult(buffer, bufferLen), "|")
End Function

Public Function ListaOcorrenciasEX() As String()
    Dim retorno   As Long
    Dim buffer    As String
    Dim bufferLen As Long

    bufferLen = BUFFER_LENGTH
    buffer = String$(bufferLen, " ")
    
    retorno = Boleto_ListaOcorrenciasEX(libHandler, buffer, bufferLen)
    CheckResult retorno
    
    ListaOcorrenciasEX = Split(processResult(buffer, bufferLen), "|")
End Function

Public Function TamNossoNumero(ByVal eCarteira As String, ByVal enossoNumero As String, ByVal eConvenio As String) As Long
    Dim retorno   As Long
    
    retorno = Boleto_TamNossoNumero(libHandler, eCarteira, enossoNumero, eConvenio)
    CheckResult retorno
    
    TamNossoNumero = retorno
End Function

Public Function CodigosMoraAceitos() As String
    Dim retorno   As Long
    Dim buffer    As String
    Dim bufferLen As Long

    bufferLen = BUFFER_LENGTH
    buffer = String$(bufferLen, " ")
    
    retorno = Boleto_CodigosMoraAceitos(libHandler, buffer, bufferLen)
    CheckResult retorno
    
    CodigosMoraAceitos = processResult(buffer, bufferLen)
End Function

Public Sub SelecionaBanco(ByVal eCodBanco As String)
    Dim retorno   As Long
    
    retorno = Boleto_SelecionaBanco(libHandler, eCodBanco)
    CheckResult retorno
End Sub

Public Function MontarNossoNumero(ByVal eIndice As Long) As String
    Dim retorno   As Long
    Dim buffer    As String
    Dim bufferLen As Long

    bufferLen = BUFFER_LENGTH
    buffer = String$(bufferLen, " ")
    
    retorno = Boleto_MontarNossoNumero(libHandler, eIndice, buffer, bufferLen)
    CheckResult retorno
    
    MontarNossoNumero = processResult(buffer, bufferLen)
End Function

Public Function RetornaLinhaDigitavel(ByVal eIndice As Long) As String
    Dim retorno   As Long
    Dim buffer    As String
    Dim bufferLen As Long

    bufferLen = BUFFER_LENGTH
    buffer = String$(bufferLen, " ")
    
    retorno = Boleto_RetornaLinhaDigitavel(libHandler, eIndice, buffer, bufferLen)
    CheckResult retorno
    
    RetornaLinhaDigitavel = processResult(buffer, bufferLen)
End Function

Public Function RetornaCodigoBarras(ByVal eIndice As Long) As String
    Dim retorno   As Long
    Dim buffer    As String
    Dim bufferLen As Long

    bufferLen = BUFFER_LENGTH
    buffer = String$(bufferLen, " ")
    
    retorno = Boleto_RetornaCodigoBarras(libHandler, eIndice, buffer, bufferLen)
    CheckResult retorno
    
    RetornaCodigoBarras = processResult(buffer, bufferLen)
End Function
                                     
Private Sub CheckResult(ByVal Resultado As Long)
    
    If Resultado >= 0 Then Exit Sub
         
    Dim buffer As String
    Dim bufferLen As Long

    bufferLen = BUFFER_LENGTH
    buffer = String$(bufferLen, " ")
    Boleto_UltimoRetorno libHandler, buffer, bufferLen
    
    Err.Raise Resultado, "ACBrBoleto", processResult(buffer, bufferLen)
End Sub

Private Function processResult(ByRef buffer As String, ByRef bufferLen As Long) As String
    
    If bufferLen > BUFFER_LENGTH Then
        buffer = String$(bufferLen, " ")
        Boleto_UltimoRetorno libHandler, buffer, bufferLen
    End If

    processResult = Trim$(FromUTF8(buffer))
End Function
