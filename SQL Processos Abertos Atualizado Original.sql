declare
	@DataInicial		VARCHAR(10) = ?,
	@DataFinal			VARCHAR(10) = ?,
	@TipoRelatorio		TINYINT	= 1,
	@idSessao			INT		= NULL
	

	DECLARE @MsgErro	VARCHAR(255)

	--

	IF @DataInicial IS NULL OR @DataFinal IS NULL
	BEGIN		
		SET	@MsgErro = 'Favor inserir o período.'
		GOTO TrataErro		
	END

	SET @DataInicial = SUBSTRING(@DataInicial,7,4) + SUBSTRING(@DataInicial,4,2) + SUBSTRING(@DataInicial,1,2)
	SET @DataFinal = SUBSTRING(@DataFinal,7,4) + SUBSTRING(@DataFinal,4,2) + SUBSTRING(@DataFinal,1,2)

	IF ISDATE(@DataInicial) = 0
	BEGIN
		SET	@MsgErro = 'Data Inicial inválida.'
		GOTO TrataErro		
	END

	IF ISDATE(@DataFinal) = 0
	BEGIN
		SET	@MsgErro = 'Data Final inválida.'
		GOTO TrataErro		
	END

	IF CONVERT(datetime,@DataInicial) > CONVERT(DATETIME,@DataFinal)
	BEGIN
		SET @MsgErro = 'Data Inicial maior que a Data Final.'
		GOTO TrataErro
	END

	IF DATEDIFF(day, @DataInicial, @DataFinal) > 30
	BEGIN
		SET @MsgErro = 'Período máximo deve ser de 30 dias.'
		GOTO TrataErro
	END

	IF NULLIF(@TipoRelatorio,0) IS NULL
	BEGIN
		SET @MsgErro = 'É necessário selecionar o tipo de relatório.'
		GOTO TrataErro
	END

	SET NOCOUNT ON
		
	IF @TipoRelatorio = 1 -- Por Data Abertura
	BEGIN

		SELECT	b.Placa, 
				dbo.fnTextoRetorno(b.Renavam,11,'N') Renavam, 
				LTRIM(RTRIM(b.Chassi)) Chassi,
				CASE WHEN c.IdVistoria IS NULL THEN 'ISENTO' WHEN c.VistoriaEletronica IS NULL THEN 'DETRAN' ELSE 'ECV' END Vistoria,
				CASE WHEN c.IdVistoria IS NULL THEN 'ISENTO' WHEN c.VistoriaEletronica IS NULL THEN ISNULL(f.DocPrincipal,'ISENTO') ELSE ISNULL(e.CPFVistoriador,'ISENTO') END as 'CPF Usuario Vistoria', 
				ISNULL(h.DocPrincipal,'ISENTO') as 'CNPJ ECV',
				a.ProcessoPlenus + '/' + a.anoProcesso Processo,
				dbo.fn_Rev_CodServicosProcesso(a.idProcesso) as Servico, 
				CONVERT(VARCHAR(10),a.DataInclusao, 103) as 'Data Abertura', 
				RIGHT(a.UsuarioInclusao,11) as 'Usuario Abertura',
				dbo.fn_Rev_MunicipioProcesso(a.idProcesso) as 'Municipio Abertura'
		FROM vw_Rev_Processo (NOLOCK) a
		JOIN Rev_Veiculo (NOLOCK) b ON b.Sequencia = a.Sequencia 
		LEFT JOIN Rev_Vistoria (NOLOCK) c ON c.idProcesso = a.IdProcesso
		LEFT JOIN Rev_VistoriaEletronica (NOLOCK) d ON d.IdVistoria = c.idVistoria
		OUTER APPLY (SELECT TOP 1 * FROM Rev_VistoriaEletronicaOcorrencia (NOLOCK) 
						WHERE idVistoriaEletronica = d.IdVistoriaEletronica 
						ORDER BY DataResultado DESC) e
		LEFT JOIN vw_Rev_Vistoriadores (NOLOCK) f ON f.IdVistoriador = c.IdVistoriador
		LEFT JOIN Rev_ECV (NOLOCK) g ON g.idECV = d.idECV
		LEFT JOIN Gen_Pessoas (NOLOCK) h ON h.IdPessoa = g.IdPessoa
		WHERE CONVERT(VARCHAR,a.DataInclusao,112) >= @DataInicial AND CONVERT(VARCHAR,a.DataInclusao,112) <= @DataFinal
		AND a.DataCancelamento IS NULL AND a.DataAuditoria IS NOT NULL
		UNION
		SELECT	b.Placa, 
				dbo.fnTextoRetorno(b.Renavam,11,'N') Renavam, 
				LTRIM(RTRIM(b.Chassi)) Chassi,
				CASE WHEN c.IdVistoria IS NULL THEN 'ISENTO' WHEN c.VistoriaEletronica IS NULL THEN 'DETRAN' ELSE 'ECV' END Vistoria,
				CASE WHEN c.IdVistoria IS NULL THEN 'ISENTO' WHEN c.VistoriaEletronica IS NULL THEN ISNULL(f.DocPrincipal,'ISENTO') ELSE ISNULL(e.CPFVistoriador,'ISENTO') END as 'CPF Usuario Vistoria', 
				ISNULL(h.DocPrincipal,'ISENTO') as 'CNPJ ECV',
				a.ProcessoPlenus + '/' + a.anoProcesso Processo,
				dbo.fn_Rev_CodServicosProcesso(a.idProcesso) as Servico, 
				CONVERT(VARCHAR(10),a.DataInclusao, 103) as 'Data Abertura', 
				RIGHT(a.UsuarioInclusao,11) as 'Usuario Abertura',
				dbo.fn_Rev_MunicipioProcesso(a.idProcesso) as 'Municipio Abertura'
		FROM vw_Rev_Processo (NOLOCK) a
		JOIN Rev_Espelho (NOLOCK) b ON b.Sequencia = a.Sequencia
		LEFT JOIN Rev_Vistoria (NOLOCK) c ON c.idProcesso = a.IdProcesso
		LEFT JOIN Rev_VistoriaEletronica (NOLOCK) d ON d.IdVistoria = c.idVistoria
		OUTER APPLY (SELECT TOP 1 * FROM Rev_VistoriaEletronicaOcorrencia (NOLOCK) 
						WHERE idVistoriaEletronica = d.IdVistoriaEletronica 
						ORDER BY DataResultado DESC) e
		LEFT JOIN vw_Rev_Vistoriadores (NOLOCK) f ON f.IdVistoriador = c.IdVistoriador
		LEFT JOIN Rev_ECV (NOLOCK) g ON g.idECV = d.idECV
		LEFT JOIN Gen_Pessoas (NOLOCK) h ON h.IdPessoa = g.IdPessoa
		WHERE  CONVERT(VARCHAR,a.DataInclusao,112) >= @DataInicial AND CONVERT(VARCHAR,a.DataInclusao,112) <= @DataFinal
			AND a.DataCancelamento IS NULL 
		ORDER BY 'Data Abertura'

	END
	ELSE IF @TipoRelatorio = 2 -- Por Data Auditoria Operador
	BEGIN

		SELECT	c.Placa,
				dbo.fnTextoRetorno(c.Renavam,11,'N') Renavam, 
				LTRIM(RTRIM(c.Chassi)) Chassi,
				a.ProcessoPlenus + '/' + a.anoProcesso Processo,
				CONVERT(VARCHAR(10),b.DataExecucao, 103) DataAuditoria,
				RIGHT(UsuarioExecucao,11) UsuarioAuditoria,
				dbo.fn_Rev_MunicipioProcesso(a.idProcesso) MunicipioAuditoria
		FROM vw_Rev_Processo (NOLOCK) a
		JOIN Rev_ItemProcesso (NOLOCK) b ON a.idProcesso = b.idProcesso AND IdServico = (Select idServico from Rev_Servico where CodigoServico = '067')--Auditoria (Conferência)
		JOIN Rev_Veiculo (NOLOCK) c ON c.Sequencia = a.Sequencia
		WHERE CONVERT(VARCHAR,a.DataAuditoria,112) >= @DataInicial AND CONVERT(VARCHAR,a.DataAuditoria,112) <= @DataFinal
			AND a.DataCancelamento IS NULL and a.DataAuditoria IS NOT NULL 
		ORDER BY a.DataAuditoria

	END
	ELSE IF @TipoRelatorio = 3 -- Por Registro na BIN
	BEGIN

		SELECT	b.Placa,
				dbo.fnTextoRetorno(b.Renavam,11,'N') Renavam, 
				LTRIM(RTRIM(b.Chassi)) Chassi,
				CONVERT(VARCHAR, a.ProcessoPLENUS) + '/' + CONVERT(VARCHAR, a.anoProcesso) Processo,
				CONVERT(VARCHAR(10),c.DataExecucao,103) DataRegistroBIN
		FROM vw_Rev_Processo (NOLOCK) a
		JOIN Rev_Veiculo (NOLOCK) b ON b.Sequencia = a.Sequencia
		JOIN Rev_ItemProcesso (NOLOCK) c on c.idProcesso = a.idProcesso AND IdServico = (Select idServico from Rev_Servico where CodigoServico = '068') --Registro(BIN)
		WHERE CONVERT(VARCHAR,c.DataExecucao,112) >= @DataInicial AND CONVERT(VARCHAR,c.DataExecucao,112) <= @DataFinal
			AND a.DataCancelamento IS NULL
		ORDER BY c.DataExecucao

	END
	ELSE IF @TipoRelatorio = 4 -- Por Emissão
	BEGIN

		SELECT	a.ProcessoPlenus + '/' + a.anoProcesso Processo,
				b.Placa, 
				dbo.fnTextoRetorno(b.Renavam,11,'N') Renavam, 
				LTRIM(RTRIM(b.Chassi)) Chassi,
				dbo.fn_Rev_CodServicosProcesso(a.idProcesso) Servicos, 
				CASE WHEN c.IdVistoria IS NULL THEN 'ISENTO' WHEN c.VistoriaEletronica IS NULL THEN 'DETRAN' ELSE 'ECV' END Vistoria,
				CASE WHEN c.IdVistoria IS NULL THEN 'ISENTO' WHEN c.VistoriaEletronica IS NULL THEN ISNULL(f.DocPrincipal,'ISENTO') ELSE ISNULL(e.CPFVistoriador,'ISENTO') END UsuarioVistoria, 
				ISNULL(h.DocPrincipal,'ISENTO') CNPJECV,
				CONVERT(VARCHAR(10),i.DataExecucao, 103) DataEmissao, 
				RIGHT(a.UsuarioInclusao,11) UsuarioEmissao,
				dbo.fn_Rev_MunicipioProcesso(a.idProcesso) MunicipioEmissao
		FROM vw_Rev_Processo (NOLOCK) a
		JOIN Rev_Veiculo (NOLOCK) b ON b.Sequencia = a.Sequencia 
		LEFT JOIN Rev_Vistoria (NOLOCK) c ON c.idProcesso = a.IdProcesso
		LEFT JOIN Rev_VistoriaEletronica (NOLOCK) d ON d.IdVistoria = c.idVistoria
		OUTER APPLY (SELECT TOP 1 * FROM Rev_VistoriaEletronicaOcorrencia (NOLOCK) 
						WHERE idVistoriaEletronica = d.IdVistoriaEletronica 
						ORDER BY DataResultado DESC) e
		LEFT JOIN vw_Rev_Vistoriadores (NOLOCK) f ON f.IdVistoriador = c.IdVistoriador
		LEFT JOIN Rev_ECV (NOLOCK) g ON g.idECV = d.idECV
		LEFT JOIN Gen_Pessoas (NOLOCK) h ON h.IdPessoa = g.IdPessoa
		JOIN Rev_ItemProcesso (NOLOCK) i on i.idProcesso = a.idProcesso AND IdServico = (Select idServico from Rev_Servico where CodigoServico = '025') --Emissão CRV(1ª via)
		WHERE  CONVERT(VARCHAR,i.DataExecucao,112) >= @DataInicial AND CONVERT(VARCHAR,i.DataExecucao,112) <= @DataFinal
			AND a.DataCancelamento IS NULL AND a.DataAuditoria IS NOT NULL
		ORDER BY i.DataExecucao
	
	END

	
TrataErro:
	
print @MsgErro
