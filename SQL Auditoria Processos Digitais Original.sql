declare
	@DataInicial		VARCHAR(10) = ?,
	@DataFinal			VARCHAR(10) = ?,
	@idSessao			INT		= NULL


	DECLARE @MsgErro	VARCHAR(255)

	--

	IF @DataInicial IS NULL OR @DataFinal IS NULL
	BEGIN		
		SET	@MsgErro = 'Favor inserir o per�odo.'
		GOTO TrataErro		
	END

	SET @DataInicial = SUBSTRING(@DataInicial,7,4) + SUBSTRING(@DataInicial,4,2) + SUBSTRING(@DataInicial,1,2)
	SET @DataFinal = SUBSTRING(@DataFinal,7,4) + SUBSTRING(@DataFinal,4,2) + SUBSTRING(@DataFinal,1,2)

	IF ISDATE(@DataInicial) = 0
	BEGIN
		SET	@MsgErro = 'Data Inicial inv�lida.'
		GOTO TrataErro		
	END

	IF ISDATE(@DataFinal) = 0
	BEGIN
		SET	@MsgErro = 'Data Final inv�lida.'
		GOTO TrataErro		
	END

	IF CONVERT(datetime,@DataInicial) > CONVERT(DATETIME,@DataFinal)
	BEGIN
		SET @MsgErro = 'Data Inicial maior que a Data Final.'
		GOTO TrataErro
	END

	IF DATEDIFF(day, @DataInicial, @DataFinal) > 30
	BEGIN
		SET @MsgErro = 'Per�odo m�ximo deve ser de 30 dias.'
		GOTO TrataErro
	END

	--
	--

	SET NOCOUNT ON
		
	SELECT	NumeroOrdemServico as Numero,
			AnoOrdemServico as Ano,
			Placa, 
			'Deferido' Resultado, 
			DataInteracao, 
			CpfOperador CPFAuditor,
			ISNULL(trim(b.Nome),CpfOperador) NomeAuditor,
			c.idsessaoabertura,
			--dbo.fn_CPFOperadorSessao(c.idsessaoabertura) CPFAberturaProcesso,
			--trim(dbo.fn_NomeOperadorSessao(c.idsessaoabertura)) NomeAberturaProcesso,
			c.DataProcesso DataAberturaProcesso

	INTO #TempProcessosAbertos

	FROM	Rev_Processo_HistoricoProcesso a 
	LEFT JOIN	Gen_Pessoas b on a.CpfOperador = b.DocPrincipal
	JOIN	(select ProcessoPlenus, AnoProcesso, IdSessaoAbertura, DataProcesso 
				from Gen_Processo g join Rev_Processo r on r.idProcesso = g.idProcesso) c ON c.ProcessoPlenus = dbo.fnTextoRetorno(a.NumeroOrdemServico,8,'N') AND c.AnoProcesso = a.AnoOrdemServico 
	WHERE	StatusAndamento = 'COD07'
		AND NOT EXISTS(SELECT * FROM Rev_Processo_HistoricoProcesso d 
							WHERE a.NumeroOrdemServico = d.NumeroOrdemServico 
							AND a.AnoOrdemServico = d.AnoOrdemServico 
							AND a.placa = d.placa 
							AND StatusAndamento = 'COD07'
							AND d.datainteracao < a.datainteracao) 
		AND CONVERT(VARCHAR,DataInteracao,112) >= @DataInicial 
		AND CONVERT(VARCHAR,DataInteracao,112) <= @DataFinal
	
	UNION

	SELECT	NumeroOrdemServico as Numero,
			AnoOrdemServico as Ano,
			Placa, 
			'Pendencia' Resultado, 
			DataInteracao, 
			CpfOperador CPFAuditor,
			trim(b.Nome) NomeAuditor,
			c.idsessaoabertura,
			--dbo.fn_CPFOperadorSessao(c.idsessaoabertura) CPFAberturaProcesso,
			--trim(dbo.fn_NomeOperadorSessao(c.idsessaoabertura)) NomeAberturaProcesso,
			c.DataProcesso DataAberturaProcesso
	FROM	Rev_Processo_HistoricoProcesso a 
	JOIN	Gen_Pessoas b ON a.CpfOperador = b.DocPrincipal
	JOIN	(select processoplenus,anoprocesso,idsessaoabertura,DataProcesso 
				from gen_processo g join rev_processo r on r.idprocesso = g.idprocesso) c ON c.processoplenus = dbo.fnTextoRetorno(a.NumeroOrdemServico,8,'N') AND c.anoprocesso = a.AnoOrdemServico
	WHERE	StatusAndamento = 'COD06-P'
	AND NOT EXISTS(SELECT * FROM Rev_Processo_HistoricoProcesso d 
							WHERE a.NumeroOrdemServico = d.NumeroOrdemServico 
							AND a.AnoOrdemServico = d.AnoOrdemServico 
							AND a.placa = d.placa 
							AND StatusAndamento = 'COD06-P'
							AND d.datainteracao < a.datainteracao and a.Observacao_Motivo = d.Observacao_Motivo) 
		AND	CONVERT(VARCHAR,DataInteracao,112) >= @DataInicial 
		AND CONVERT(VARCHAR,DataInteracao,112) <= @DataFinal
	
	UNION

	SELECT	NumeroOrdemServico as Numero,
			AnoOrdemServico as Ano,
			Placa, 
			'Indeferido' Resultado, 
			DataInteracao, 
			CpfOperador CPFAuditor,
			trim(b.Nome) NomeAuditor,
			c.idsessaoabertura,
			--dbo.fn_CPFOperadorSessao(c.idsessaoabertura) CPFAberturaProcesso,
			--trim(dbo.fn_NomeOperadorSessao(c.idsessaoabertura)) NomeAberturaProcesso,
			c.DataProcesso DataAberturaProcesso
	FROM	Rev_Processo_HistoricoProcesso a 
	JOIN	Gen_Pessoas b on a.CpfOperador = b.DocPrincipal
	JOIN	(Select ProcessoPlenus, AnoProcesso, IdSessaoAbertura, DataProcesso 
				from Gen_Processo g join Rev_Processo r on r.idProcesso = g.idProcesso) c ON c.ProcessoPlenus = dbo.fnTextoRetorno(a.NumeroOrdemServico,8,'N') AND c.AnoProcesso = a.AnoOrdemServico 
	WHERE	StatusAndamento = 'COD06-I'
		AND NOT EXISTS(SELECT * FROM Rev_Processo_HistoricoProcesso d 
							WHERE a.NumeroOrdemServico = d.NumeroOrdemServico 
							AND a.AnoOrdemServico = d.AnoOrdemServico 
							AND a.placa = d.placa 
							AND StatusAndamento = 'COD06-I'
							AND d.datainteracao < a.datainteracao) 
		AND CONVERT(VARCHAR,DataInteracao,112) >= @DataInicial 
		AND CONVERT(VARCHAR,DataInteracao,112) <= @DataFinal


	SELECT	Numero,
			Ano,
			Placa, 
			Resultado, 
			format(DataInteracao, 'dd/MM/yyyy HH:mm:ss') as Data, 
			CPFAuditor as 'CPF Auditor',
			NomeAuditor as 'Nome Auditor',
			dbo.fn_CPFOperadorSessao(idsessaoabertura) as 'CPF Abertura',
			trim(dbo.fn_NomeOperadorSessao(idsessaoabertura)) 'Nome Abertura',
			format(DataAberturaProcesso, 'dd/MM/yyyy HH:mm:ss') as 'Data Abertura'
    FROM #TempProcessosAbertos

	DROP TABLE #TempProcessosAbertos

TrataErro:
	
print @MsgErro
