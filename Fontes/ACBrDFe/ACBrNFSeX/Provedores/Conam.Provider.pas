{******************************************************************************}
{ Projeto: Componentes ACBr                                                    }
{  Biblioteca multiplataforma de componentes Delphi para intera��o com equipa- }
{ mentos de Automa��o Comercial utilizados no Brasil                           }
{                                                                              }
{ Direitos Autorais Reservados (c) 2020 Daniel Simoes de Almeida               }
{                                                                              }
{ Colaboradores nesse arquivo: Italo Giurizzato Junior                         }
{                                                                              }
{  Voc� pode obter a �ltima vers�o desse arquivo na pagina do  Projeto ACBr    }
{ Componentes localizado em      http://www.sourceforge.net/projects/acbr      }
{                                                                              }
{  Esta biblioteca � software livre; voc� pode redistribu�-la e/ou modific�-la }
{ sob os termos da Licen�a P�blica Geral Menor do GNU conforme publicada pela  }
{ Free Software Foundation; tanto a vers�o 2.1 da Licen�a, ou (a seu crit�rio) }
{ qualquer vers�o posterior.                                                   }
{                                                                              }
{  Esta biblioteca � distribu�da na expectativa de que seja �til, por�m, SEM   }
{ NENHUMA GARANTIA; nem mesmo a garantia impl�cita de COMERCIABILIDADE OU      }
{ ADEQUA��O A UMA FINALIDADE ESPEC�FICA. Consulte a Licen�a P�blica Geral Menor}
{ do GNU para mais detalhes. (Arquivo LICEN�A.TXT ou LICENSE.TXT)              }
{                                                                              }
{  Voc� deve ter recebido uma c�pia da Licen�a P�blica Geral Menor do GNU junto}
{ com esta biblioteca; se n�o, escreva para a Free Software Foundation, Inc.,  }
{ no endere�o 59 Temple Street, Suite 330, Boston, MA 02111-1307 USA.          }
{ Voc� tamb�m pode obter uma copia da licen�a em:                              }
{ http://www.opensource.org/licenses/lgpl-license.php                          }
{                                                                              }
{ Daniel Sim�es de Almeida - daniel@projetoacbr.com.br - www.projetoacbr.com.br}
{       Rua Coronel Aureliano de Camargo, 963 - Tatu� - SP - 18270-170         }
{******************************************************************************}

{
     Para que a conex�o com o webservice do provedor Conam ocorra � preciso
     configurar a propriedade HttpLib com o valor HttpWinINet
}

{$I ACBr.inc}

unit Conam.Provider;

interface

uses
  SysUtils, Classes, Variants,
  ACBrDFeSSL,
  ACBrXmlBase, ACBrXmlDocument,
  ACBrNFSeXNotasFiscais,
  ACBrNFSeXClass, ACBrNFSeXConversao,
  ACBrNFSeXGravarXml, ACBrNFSeXLerXml,
  ACBrNFSeXProviderProprio,
  ACBrNFSeXWebserviceBase, ACBrNFSeXWebservicesResponse;

type
  TACBrNFSeXWebserviceConam = class(TACBrNFSeXWebserviceSoap11)
  public
    function Recepcionar(ACabecalho, AMSG: String): string; override;
    function ConsultarSituacao(ACabecalho, AMSG: String): string; override;
    function ConsultarLote(ACabecalho, AMSG: String): string; override;
    function Cancelar(ACabecalho, AMSG: String): string; override;

  end;

  TACBrNFSeProviderConam = class (TACBrNFSeProviderProprio)
  protected
    procedure Configuracao; override;

    function CriarGeradorXml(const ANFSe: TNFSe): TNFSeWClass; override;
    function CriarLeitorXml(const ANFSe: TNFSe): TNFSeRClass; override;
    function CriarServiceClient(const AMetodo: TMetodo): TACBrNFSeXWebservice; override;

    procedure PrepararEmitir(Response: TNFSeEmiteResponse); override;
    procedure TratarRetornoEmitir(Response: TNFSeEmiteResponse); override;

    procedure PrepararConsultaSituacao(Response: TNFSeConsultaSituacaoResponse); override;
    procedure TratarRetornoConsultaSituacao(Response: TNFSeConsultaSituacaoResponse); override;

    procedure PrepararConsultaLoteRps(Response: TNFSeConsultaLoteRpsResponse); override;
    procedure TratarRetornoConsultaLoteRps(Response: TNFSeConsultaLoteRpsResponse); override;

    procedure PrepararCancelaNFSe(Response: TNFSeCancelaNFSeResponse); override;
    procedure TratarRetornoCancelaNFSe(Response: TNFSeCancelaNFSeResponse); override;

    procedure ProcessarMensagemErros(const RootNode: TACBrXmlNode;
                                     const Response: TNFSeWebserviceResponse;
                                     AListTag: string = '';
                                     AMessageTag: string = 'Erro'); override;

  end;

implementation

uses
  ACBrUtil, ACBrDFeException,
  ACBrNFSeX, ACBrNFSeXConfiguracoes, ACBrNFSeXConsts,
  Conam.GravarXml, Conam.LerXml;

{ TACBrNFSeProviderConam }

procedure TACBrNFSeProviderConam.Configuracao;
begin
  inherited Configuracao;

  with ConfigGeral do
  begin
    Identificador := '';
    QuebradeLinha := '\\';

    UseCertificateHTTP := False;
    ModoEnvio := meLoteAssincrono;
    ConsultaNFSe := False;
  end;

  SetXmlNameSpace('');

  with ConfigMsgDados do
  begin
    Prefixo := 'nfe';
    PrefixoTS := 'nfe';
  end;

  ConfigSchemas.Validar := False;
end;

function TACBrNFSeProviderConam.CriarGeradorXml(
  const ANFSe: TNFSe): TNFSeWClass;
begin
  Result := TNFSeW_Conam.Create(Self);
  Result.NFSe := ANFSe;
end;

function TACBrNFSeProviderConam.CriarLeitorXml(
  const ANFSe: TNFSe): TNFSeRClass;
begin
  Result := TNFSeR_Conam.Create(Self);
  Result.NFSe := ANFSe;
end;

function TACBrNFSeProviderConam.CriarServiceClient(
  const AMetodo: TMetodo): TACBrNFSeXWebservice;
var
  URL: string;
begin
  URL := GetWebServiceURL(AMetodo);

  if URL <> '' then
    Result := TACBrNFSeXWebserviceConam.Create(FAOwner, AMetodo, URL)
  else
  begin
    if ConfigGeral.Ambiente = taProducao then
      raise EACBrDFeException.Create(ERR_SEM_URL_PRO)
    else
      raise EACBrDFeException.Create(ERR_SEM_URL_HOM);
  end;
end;

procedure TACBrNFSeProviderConam.ProcessarMensagemErros(
  const RootNode: TACBrXmlNode; const Response: TNFSeWebserviceResponse;
  AListTag, AMessageTag: string);
var
  I: Integer;
  ANode: TACBrXmlNode;
  ANodeArray: TACBrXmlNodeArray;
  AErro: TNFSeEventoCollectionItem;
  xId: string;
begin
  ANode := RootNode.Childrens.FindAnyNs(AListTag);

  if (ANode = nil) then
    ANode := RootNode;

  ANodeArray := ANode.Childrens.FindAllAnyNs(AMessageTag);

  if not Assigned(ANodeArray) then Exit;

  for I := Low(ANodeArray) to High(ANodeArray) do
  begin
    xId := ObterConteudoTag(ANodeArray[I].Childrens.FindAnyNs('Id'), tcStr);

    if xId <> 'OK' then
    begin
      AErro := Response.Erros.New;
      AErro.Codigo := xId;
      AErro.Descricao := ObterConteudoTag(ANodeArray[I].Childrens.FindAnyNs('Description'), tcStr);
      AErro.Correcao := '';
    end;
  end;
end;

procedure TACBrNFSeProviderConam.PrepararEmitir(Response: TNFSeEmiteResponse);
var
  AErro: TNFSeEventoCollectionItem;
  Emitente: TEmitenteConfNFSe;
  Nota: TNotaFiscal;
  IdAttr, ListaRps, xRps, xOptante, xReg90, Aliquota: string;
  I, QtdTributos: Integer;
  vTotServicos, vTotISS, vTotISSRetido, vTotDeducoes, vTotTributos,
  AliquotaSN: Double;
  OptanteSimples: TnfseSimNao;
  ExigibilidadeISS: TnfseExigibilidadeISS;
  DataOptanteSimples, DataInicial, DataFinal: TDateTime;
begin
  if TACBrNFSeX(FAOwner).NotasFiscais.Count <= 0 then
  begin
    AErro := Response.Erros.New;
    AErro.Codigo := Cod002;
    AErro.Descricao := Desc002;
  end;

  if TACBrNFSeX(FAOwner).NotasFiscais.Count > Response.MaxRps then
  begin
    AErro := Response.Erros.New;
    AErro.Codigo := Cod003;
    AErro.Descricao := 'Conjunto de RPS transmitidos (m�ximo de ' +
                       IntToStr(Response.MaxRps) + ' RPS)' +
                       ' excedido. Quantidade atual: ' +
                       IntToStr(TACBrNFSeX(FAOwner).NotasFiscais.Count);
  end;

  if Response.Erros.Count > 0 then Exit;

  ListaRps := '';

  if ConfigAssinar.IncluirURI then
    IdAttr := ConfigGeral.Identificador
  else
    IdAttr := 'ID';

  DataInicial := 0;
  DataFinal := 0;
  DataOptanteSimples := 0;
  OptanteSimples := snSim;
  ExigibilidadeISS := exiExigivel;
  QtdTributos   := 0;
  vTotServicos  := 0;
  vTotISS       := 0;
  vTotISSRetido := 0;
  vTotDeducoes  := 0;
  vTotTributos  := 0;

  for I := 0 to TACBrNFSeX(FAOwner).NotasFiscais.Count -1 do
  begin
    Nota := TACBrNFSeX(FAOwner).NotasFiscais.Items[I];

    if EstaVazio(Nota.XMLAssinado) then
    begin
      Nota.GerarXML;

      Nota.XMLOriginal := ConverteXMLtoUTF8(Nota.XMLOriginal);
      Nota.XMLOriginal := ChangeLineBreak(Nota.XMLOriginal, '');

      if ConfigAssinar.Rps or ConfigAssinar.RpsGerarNFSe then
      begin
        Nota.XMLOriginal := FAOwner.SSL.Assinar(Nota.XMLOriginal,
                                                ConfigMsgDados.XmlRps.DocElemento,
                                                ConfigMsgDados.XmlRps.InfElemento, '', '', '', IdAttr);
      end;
    end;

    if FAOwner.Configuracoes.Arquivos.Salvar then
    begin
      if NaoEstaVazio(Nota.NomeArqRps) then
        TACBrNFSeX(FAOwner).Gravar(Nota.NomeArqRps, Nota.XMLOriginal)
      else
      begin
        Nota.NomeArqRps := Nota.CalcularNomeArquivoCompleto(Nota.NomeArqRps, '');
        TACBrNFSeX(FAOwner).Gravar(Nota.NomeArqRps, Nota.XMLOriginal);
      end;
    end;

    if i = 0 then
    begin
      OptanteSimples := Nota.NFSe.OptanteSimplesNacional;
      ExigibilidadeISS := Nota.NFSe.Servico.ExigibilidadeISS;
      DataOptanteSimples := Nota.NFSe.DataOptanteSimplesNacional;
      DataInicial := Nota.NFSe.DataEmissao;
      DataFinal := DataInicial;
      AliquotaSN := Nota.NFSe.Servico.Valores.AliquotaSN;
      Aliquota := FormatFloat('#.00', AliquotaSN);
      Aliquota := StringReplace(Aliquota, '.', ',', [rfReplaceAll]);
    end;

    if Nota.NFSe.DataEmissao < DataInicial then
      DataInicial := Nota.NFSe.DataEmissao;

    if Nota.NFSe.DataEmissao > DataFinal then
      DataFinal := Nota.NFSe.DataEmissao;

    if Nota.NFSe.Servico.Valores.AliquotaPis > 0 then
      QtdTributos := QtdTributos + 1;

    if Nota.NFSe.Servico.Valores.AliquotaCofins > 0 then
      QtdTributos := QtdTributos + 1;

    if Nota.NFSe.Servico.Valores.AliquotaCsll > 0 then
      QtdTributos := QtdTributos + 1;

    if Nota.NFSe.Servico.Valores.AliquotaInss > 0 then
      QtdTributos := QtdTributos + 1;

    if Nota.NFSe.Servico.Valores.AliquotaIr > 0 then
      QtdTributos := QtdTributos + 1;

    vTotServicos := vTotServicos + Nota.NFSe.Servico.Valores.ValorServicos;
    vTotDeducoes := vTotDeducoes + Nota.NFSe.Servico.Valores.ValorDeducoes;
    vTotISS      := vTotISS + Nota.NFSe.Servico.Valores.ValorIss;
    vTotISSRetido := vTotISSRetido +  Nota.NFSe.Servico.Valores.ValorIssRetido;
    vTotTributos  := vTotTributos +
             Nota.NFSe.Servico.Valores.ValorIr +
             Nota.NFSe.Servico.Valores.ValorCofins +
             Nota.NFSe.Servico.Valores.ValorPis +
             Nota.NFSe.Servico.Valores.ValorInss +
             Nota.NFSe.Servico.Valores.ValorCsll;

    xRps := RemoverDeclaracaoXML(Nota.XMLOriginal);

    xRps := '<nfe:Reg20Item>' + SeparaDados(xRps, 'nfe:Reg20Item') + '</nfe:Reg20Item>';

    ListaRps := ListaRps + xRps;
  end;

  Emitente := TACBrNFSeX(FAOwner).Configuracoes.Geral.Emitente;

  if EstaVazio(Emitente.WSUser) then
  begin
    AErro := Response.Erros.New;
    AErro.Codigo := Cod119;
    AErro.Descricao := Desc119;
    Exit;
  end;

  if EstaVazio(Emitente.WSSenha) then
  begin
    AErro := Response.Erros.New;
    AErro.Codigo := Cod120;
    AErro.Descricao := Desc120;
    Exit;
  end;

  ListaRps := ChangeLineBreak(ListaRps, '');

  if OptanteSimples = snSim then
  begin
    xOptante := '<nfe:TipoTrib>4</nfe:TipoTrib>' +
                '<nfe:DtAdeSN>' +
                   FormatDateTime('dd/mm/yyyy', DataOptanteSimples) +
                '</nfe:DtAdeSN>' +
                '<nfe:AlqIssSN_IP>' +
                   Aliquota +
                '</nfe:AlqIssSN_IP>';
  end
  else
  begin
    case ExigibilidadeISS of
      exiExigivel:
        xOptante := '<nfe:TipoTrib>1</nfe:TipoTrib>';

      exiNaoIncidencia,
      exiIsencao,
      exiImunidade:
        xOptante := '<nfe:TipoTrib>2</nfe:TipoTrib>';

      exiSuspensaDecisaoJudicial,
      exiSuspensaProcessoAdministrativo:
        xOptante := '<nfe:TipoTrib>3</nfe:TipoTrib>';

      exiExportacao:
        xOptante := '<nfe:TipoTrib>5</nfe:TipoTrib>';
    end;
  end;

  xReg90 := '<nfe:Reg90>' +
              '<nfe:QtdRegNormal>' +
                 IntToStr(TACBrNFSeX(FAOwner).NotasFiscais.Count) +
              '</nfe:QtdRegNormal>' +
              '<nfe:ValorNFS>' +
                 StringReplace(FormatFloat('#.00', vTotServicos), '.', ',', [rfReplaceAll]) +
              '</nfe:ValorNFS>' +
              '<nfe:ValorISS>' +
                 StringReplace(FormatFloat('#.00', vTotISS), '.', ',', [rfReplaceAll]) +
              '</nfe:ValorISS>' +
              '<nfe:ValorDed>' +
                 StringReplace(FormatFloat('#.00', vTotDeducoes), '.', ',', [rfReplaceAll]) +
              '</nfe:ValorDed>' +
              '<nfe:ValorIssRetTom>' +
                 StringReplace(FormatFloat('#.00', vTotISSRetido), '.', ',', [rfReplaceAll]) +
              '</nfe:ValorIssRetTom>' +
              '<nfe:QtdReg30>' +
                 IntToStr(QtdTributos) +
              '</nfe:QtdReg30>' +
              '<nfe:ValorTributos>' +
                 StringReplace(FormatFloat('#.00', vTotTributos), '.', ',', [rfReplaceAll]) +
              '</nfe:ValorTributos>' +
            '</nfe:Reg90>';

  Response.ArquivoEnvio := '<nfe:Sdt_processarpsin>' +
                         '<nfe:Login>' +
                           '<nfe:CodigoUsuario>' +
                              Emitente.WSUser +
                           '</nfe:CodigoUsuario>' +
                           '<nfe:CodigoContribuinte>' +
                              Emitente.WSSenha +
                           '</nfe:CodigoContribuinte>' +
                         '</nfe:Login>' +
                         '<nfe:SDTRPS>' +
                           '<nfe:Ano>' +
                              FormatDateTime('yyyy', DataInicial) +
                           '</nfe:Ano>' +
                           '<nfe:Mes>' +
                              FormatDateTime('mm', DataInicial) +
                           '</nfe:Mes>' +
                           '<nfe:CPFCNPJ>' +
                              Emitente.CNPJ +
                           '</nfe:CPFCNPJ>' +
                           '<nfe:DTIni>' +
                              FormatDateTime('dd/mm/yyyy', DataInicial) +
                           '</nfe:DTIni>' +
                           '<nfe:DTFin>' +
                              FormatDateTime('dd/mm/yyyy', DataFinal) +
                           '</nfe:DTFin>' +
                           xOptante +
                           '<nfe:Versao>2.00</nfe:Versao>' +
                           '<nfe:Reg20>' +
                              ListaRps +
                           '</nfe:Reg20>' +
                           xReg90 +
                         '</nfe:SDTRPS>' +
                       '</nfe:Sdt_processarpsin>';
end;

procedure TACBrNFSeProviderConam.TratarRetornoEmitir(Response: TNFSeEmiteResponse);
var
  Document: TACBrXmlDocument;
  AErro: TNFSeEventoCollectionItem;
  ANode: TACBrXmlNode;
begin
  Document := TACBrXmlDocument.Create;

  try
    try
      if Response.ArquivoRetorno = '' then
      begin
        AErro := Response.Erros.New;
        AErro.Codigo := Cod201;
        AErro.Descricao := Desc201;
        Exit
      end;

      Document.LoadFromXml(Response.ArquivoRetorno);

      ProcessarMensagemErros(Document.Root, Response, 'Messages', 'Message');

      Response.Sucesso := (Response.Erros.Count = 0);

      ANode := Document.Root;

      if ANode <> nil then
      begin
        with Response do
        begin
          Protocolo := ObterConteudoTag(ANode.Childrens.FindAnyNs('Protocolo'), tcStr);
        end;
      end;
    except
      on E:Exception do
      begin
        AErro := Response.Erros.New;
        AErro.Codigo := Cod999;
        AErro.Descricao := Desc999 + E.Message;
      end;
    end;
  finally
    FreeAndNil(Document);
  end;
end;

procedure TACBrNFSeProviderConam.PrepararConsultaSituacao(
  Response: TNFSeConsultaSituacaoResponse);
var
  AErro: TNFSeEventoCollectionItem;
  Emitente: TEmitenteConfNFSe;
begin
  if EstaVazio(Response.Protocolo) then
  begin
    AErro := Response.Erros.New;
    AErro.Codigo := Cod101;
    AErro.Descricao := Desc101;
    Exit;
  end;

  Emitente := TACBrNFSeX(FAOwner).Configuracoes.Geral.Emitente;

  if EstaVazio(Emitente.WSUser) then
  begin
    AErro := Response.Erros.New;
    AErro.Codigo := Cod119;
    AErro.Descricao := Desc119;
    Exit;
  end;

  if EstaVazio(Emitente.WSSenha) then
  begin
    AErro := Response.Erros.New;
    AErro.Codigo := Cod120;
    AErro.Descricao := Desc120;
    Exit;
  end;

  Response.ArquivoEnvio := '<nfe:Sdt_consultaprotocoloin>' +
                         '<nfe:Protocolo>' +
                            Response.Protocolo +
                         '</nfe:Protocolo>' +
                         '<nfe:Login>' +
                           '<nfe:CodigoUsuario>' +
                              Emitente.WSUser +
                           '</nfe:CodigoUsuario>' +
                           '<nfe:CodigoContribuinte>' +
                              Emitente.WSSenha +
                           '</nfe:CodigoContribuinte>' +
                         '</nfe:Login>' +
                       '</nfe:Sdt_consultaprotocoloin>';
end;

procedure TACBrNFSeProviderConam.TratarRetornoConsultaSituacao(
  Response: TNFSeConsultaSituacaoResponse);
var
  Document: TACBrXmlDocument;
  AErro: TNFSeEventoCollectionItem;
  ANode: TACBrXmlNode;
begin
  Document := TACBrXmlDocument.Create;

  try
    try
      if Response.ArquivoRetorno = '' then
      begin
        AErro := Response.Erros.New;
        AErro.Codigo := Cod201;
        AErro.Descricao := Desc201;
        Exit
      end;

      Document.LoadFromXml(Response.ArquivoRetorno);

      ProcessarMensagemErros(Document.Root, Response, 'Messages', 'Message');

      Response.Sucesso := (Response.Erros.Count = 0);

      ANode := Document.Root;

      if ANode <> nil then
      begin
        with Response do
        begin
          Protocolo := ObterConteudoTag(ANode.Childrens.FindAnyNs('PrtCSerRps'), tcStr);
        end;
      end;
    except
      on E:Exception do
      begin
        AErro := Response.Erros.New;
        AErro.Codigo := Cod999;
        AErro.Descricao := Desc999 + E.Message;
      end;
    end;
  finally
    FreeAndNil(Document);
  end;
end;

procedure TACBrNFSeProviderConam.PrepararConsultaLoteRps(
  Response: TNFSeConsultaLoteRpsResponse);
var
  AErro: TNFSeEventoCollectionItem;
  Emitente: TEmitenteConfNFSe;
begin
  if EstaVazio(Response.Protocolo) then
  begin
    AErro := Response.Erros.New;
    AErro.Codigo := Cod101;
    AErro.Descricao := Desc101;
    Exit;
  end;

  Emitente := TACBrNFSeX(FAOwner).Configuracoes.Geral.Emitente;

  if EstaVazio(Emitente.WSUser) then
  begin
    AErro := Response.Erros.New;
    AErro.Codigo := Cod119;
    AErro.Descricao := Desc119;
    Exit;
  end;

  if EstaVazio(Emitente.WSSenha) then
  begin
    AErro := Response.Erros.New;
    AErro.Codigo := Cod120;
    AErro.Descricao := Desc120;
    Exit;
  end;

  Response.ArquivoEnvio := '<nfe:Sdt_consultanotasprotocoloin>' +
                         '<nfe:Protocolo>' +
                            Response.Protocolo +
                         '</nfe:Protocolo>' +
                         '<nfe:Login>' +
                           '<nfe:CodigoUsuario>' +
                              Emitente.WSUser +
                           '</nfe:CodigoUsuario>' +
                           '<nfe:CodigoContribuinte>' +
                              Emitente.WSSenha +
                           '</nfe:CodigoContribuinte>' +
                         '</nfe:Login>' +
                       '</nfe:Sdt_consultanotasprotocoloin>';
end;

procedure TACBrNFSeProviderConam.TratarRetornoConsultaLoteRps(
  Response: TNFSeConsultaLoteRpsResponse);
var
  Document: TACBrXmlDocument;
  AErro: TNFSeEventoCollectionItem;
  ANode, AuxNode: TACBrXmlNode;
  ANodeArray: TACBrXmlNodeArray;
  i: Integer;
  NumRps: String;
  ANota: TNotaFiscal;
begin
  Document := TACBrXmlDocument.Create;

  try
    try
      if Response.ArquivoRetorno = '' then
      begin
        AErro := Response.Erros.New;
        AErro.Codigo := Cod201;
        AErro.Descricao := Desc201;
        Exit
      end;

      Document.LoadFromXml(Response.ArquivoRetorno);

      ProcessarMensagemErros(Document.Root, Response, 'Messages', 'Message');

      Response.Sucesso := (Response.Erros.Count = 0);

      ANode := Document.Root;

      AuxNode := ANode.Childrens.FindAnyNs('XML_Notas');

      if AuxNode <> nil then
      begin
        ANodeArray := AuxNode.Childrens.FindAllAnyNs('Reg20');

        if not Assigned(ANodeArray) then
        begin
          AErro := Response.Erros.New;
          AErro.Codigo := Cod203;
          AErro.Descricao := Desc203;
          Exit;
        end;

        for i := Low(ANodeArray) to High(ANodeArray) do
        begin
          ANode := ANodeArray[i];
          AuxNode := ANode.Childrens.FindAnyNs('Reg20Item');

          if AuxNode <> nil then
          begin
            AuxNode := AuxNode.Childrens.FindAnyNs('NumRps');

            if AuxNode <> nil then
            begin
              NumRps := AuxNode.AsString;

              ANota := TACBrNFSeX(FAOwner).NotasFiscais.FindByRps(NumRps);

              if Assigned(ANota) then
                ANota.XML := ANode.OuterXml
              else
              begin
                TACBrNFSeX(FAOwner).NotasFiscais.LoadFromString(ANode.OuterXml, False);
                ANota := TACBrNFSeX(FAOwner).NotasFiscais.Items[TACBrNFSeX(FAOwner).NotasFiscais.Count-1];
              end;

              SalvarXmlNfse(ANota);
            end;
          end;
        end;
      end;
    except
      on E:Exception do
      begin
        AErro := Response.Erros.New;
        AErro.Codigo := Cod999;
        AErro.Descricao := Desc999 + E.Message;
      end;
    end;
  finally
    FreeAndNil(Document);
  end;
end;

procedure TACBrNFSeProviderConam.PrepararCancelaNFSe(
  Response: TNFSeCancelaNFSeResponse);
var
  AErro: TNFSeEventoCollectionItem;
  Emitente: TEmitenteConfNFSe;
begin
  if EstaVazio(Response.InfCancelamento.NumeroNFSe) then
  begin
    AErro := Response.Erros.New;
    AErro.Codigo := Cod108;
    AErro.Descricao := Desc108;
    Exit;
  end;

  if EstaVazio(Response.InfCancelamento.SerieNFSe) then
  begin
    AErro := Response.Erros.New;
    AErro.Codigo := Cod112;
    AErro.Descricao := Desc112;
    Exit;
  end;

  if Response.InfCancelamento.NumeroRps = 0 then
  begin
    AErro := Response.Erros.New;
    AErro.Codigo := Cod102;
    AErro.Descricao := Desc102;
    Exit;
  end;

  if EstaVazio(Response.InfCancelamento.SerieRps) then
  begin
    AErro := Response.Erros.New;
    AErro.Codigo := Cod103;
    AErro.Descricao := Desc103;
    Exit;
  end;

  if Response.InfCancelamento.ValorNFSe = 0 then
  begin
    AErro := Response.Erros.New;
    AErro.Codigo := Cod113;
    AErro.Descricao := Desc113;
    Exit;
  end;

  if EstaVazio(Response.InfCancelamento.MotCancelamento) then
  begin
    AErro := Response.Erros.New;
    AErro.Codigo := Cod110;
    AErro.Descricao := Desc110;
    Exit;
  end;

  Emitente := TACBrNFSeX(FAOwner).Configuracoes.Geral.Emitente;

  if EstaVazio(Emitente.WSUser) then
  begin
    AErro := Response.Erros.New;
    AErro.Codigo := Cod119;
    AErro.Descricao := Desc119;
    Exit;
  end;

  if EstaVazio(Emitente.WSSenha) then
  begin
    AErro := Response.Erros.New;
    AErro.Codigo := Cod120;
    AErro.Descricao := Desc120;
    Exit;
  end;

  Response.ArquivoEnvio := '<nfe:Sdt_cancelanfe>' +
                         '<nfe:Login>' +
                           '<nfe:CodigoUsuario>' +
                              Emitente.WSUser +
                           '</nfe:CodigoUsuario>' +
                           '<nfe:CodigoContribuinte>' +
                              Emitente.WSSenha +
                           '</nfe:CodigoContribuinte>' +
                         '</nfe:Login>' +
                         '<nfe:Nota>' +
                           '<nfe:SerieNota>' +
                              Response.InfCancelamento.SerieNFSe +
                           '</nfe:SerieNota>' +
                           '<nfe:NumeroNota>' +
                              Response.InfCancelamento.NumeroNFSe +
                           '</nfe:NumeroNota>' +
                           '<nfe:SerieRPS>' +
                              Response.InfCancelamento.SerieRps +
                           '</nfe:SerieRPS>' +
                           '<nfe:NumeroRps>' +
                              IntToStr(Response.InfCancelamento.NumeroRps) +
                           '</nfe:NumeroRps>' +
                           '<nfe:ValorNota>' +
                              FormatFloat('#.00', Response.InfCancelamento.ValorNFSe) +
                           '</nfe:ValorNota>' +
                           '<nfe:MotivoCancelamento>' +
                              Response.InfCancelamento.MotCancelamento +
                           '</nfe:MotivoCancelamento>' +
                           '<nfe:PodeCancelarGuia>S</nfe:PodeCancelarGuia>' +
                         '</nfe:Nota>' +
                       '</nfe:Sdt_cancelanfe>';
end;

procedure TACBrNFSeProviderConam.TratarRetornoCancelaNFSe(
  Response: TNFSeCancelaNFSeResponse);
var
  Document: TACBrXmlDocument;
  AErro: TNFSeEventoCollectionItem;
  ANode: TACBrXmlNode;
begin
  Document := TACBrXmlDocument.Create;

  try
    try
      if Response.ArquivoRetorno = '' then
      begin
        AErro := Response.Erros.New;
        AErro.Codigo := Cod201;
        AErro.Descricao := Desc201;
        Exit
      end;

      Document.LoadFromXml(Response.ArquivoRetorno);

      ProcessarMensagemErros(Document.Root, Response, 'Messages', 'Message');

      Response.Sucesso := (Response.Erros.Count = 0);

      ANode := Document.Root;

      if ANode <> nil then
      begin
        with Response do
        begin
          Protocolo := ObterConteudoTag(ANode.Childrens.FindAnyNs('PrtCSerRps'), tcStr);
        end;
      end;
    except
      on E:Exception do
      begin
        AErro := Response.Erros.New;
        AErro.Codigo := Cod999;
        AErro.Descricao := Desc999 + E.Message;
      end;
    end;
  finally
    FreeAndNil(Document);
  end;
end;

{ TACBrNFSeXWebserviceConam }

function TACBrNFSeXWebserviceConam.Recepcionar(ACabecalho,
  AMSG: String): string;
var
  Request: string;
begin
  FPMsgOrig := AMSG;

  Request := '<nfe:ws_nfe.PROCESSARPS>';
  Request := Request + AMSG;
  Request := Request + '</nfe:ws_nfe.PROCESSARPS>';

  Result := Executar('NFeaction/AWS_NFE.PROCESSARPS', Request,
                     ['Sdt_processarpsout'],
                     ['xmlns:nfe="NFe"']);
end;

function TACBrNFSeXWebserviceConam.ConsultarSituacao(ACabecalho,
  AMSG: String): string;
var
  Request: string;
begin
  FPMsgOrig := AMSG;

  Request := '<nfe:ws_nfe.CONSULTAPROTOCOLO>';
  Request := Request + AMSG;
  Request := Request + '</nfe:ws_nfe.CONSULTAPROTOCOLO>';

  Result := Executar('NFeaction/AWS_NFE.CONSULTAPROTOCOLO', Request,
                     ['Sdt_consultaprotocoloout'],
                     ['xmlns:nfe="NFe"']);
end;

function TACBrNFSeXWebserviceConam.ConsultarLote(ACabecalho,
  AMSG: String): string;
var
  Request: string;
begin
  FPMsgOrig := AMSG;

  Request := '<nfe:ws_nfe.CONSULTANOTASPROTOCOLO>';
  Request := Request + AMSG;
  Request := Request + '</nfe:ws_nfe.CONSULTANOTASPROTOCOLO>';

  Result := Executar('NFeaction/AWS_NFE.CONSULTANOTASPROTOCOLO', Request,
                     ['Sdt_consultanotasprotocoloout'],
                     ['xmlns:nfe="NFe"']);
end;

function TACBrNFSeXWebserviceConam.Cancelar(ACabecalho, AMSG: String): string;
var
  Request: string;
begin
  FPMsgOrig := AMSG;

  Request := '<nfe:ws_nfe.CANCELANOTAELETRONICA>';
  Request := Request + AMSG;
  Request := Request + '</nfe:ws_nfe.CANCELANOTAELETRONICA>';

  Result := Executar('NFeaction/AWS_NFE.CANCELANOTAELETRONICA', Request,
                     ['Sdt_retornocancelanfe'],
                     ['xmlns:nfe="NFe"']);
end;

end.
