/*
 * PLT053 - Script para o relatório de Inadimplencia
 * @param CODFILIAL				Código da Filial
 * @param DTVENCIMENTO			Data de Vencimentos
 *
 * @author  Marcelo Valvassori Bittencourt
 * @mail	webmaster@pallottism.com.br
 * @version 1.0 bitts 17/04/2017
 * 
*/


DECLARE 
	@DTVENCIMENTO VARCHAR(10) = '07/07/2017',
	@CODFILIAL VARCHAR(5) = '1';

SELECT
	A.RA, 
	UPPER(C.NOME) AS ALUNO, 
	H.NOME AS CURSO,
	K.CODPERLET AS [PERIODO LETIVO],
	A.CODFILIAL, 
	A1.DESCRICAO AS [STATUS MATRICULA], 
	A2.DESCRICAO AS [STATUS FINAL],
	L.IDLAN AS REF,
	J.PARCELA,
	CONVERT(VARCHAR, M.DATAVENCIMENTO, 103) AS VENCIMENTO,
	M.VALORORIGINAL AS [VALOR ORIGINAL],
	M.VALOROP1, 
	M.VALOROP2,
	ISNULL([GRATUIDADE].VALORGRATUIDADE,0) AS [VALOR GRATUIDADE],
	ISNULL([GRATUIDADE TOTAL].VALORGRATUIDADETOTAL,0) AS [GRATUIDADE 100%],
	ISNULL([GRATUIDADE PARCIAL].VALORGRATUIDADEPARCIAL,0) AS [GRATUIDADE 50%],
	ISNULL([GRATUIDADE ESPECIAL].VALORGRATUIDADEESP,0) AS [GRATUIDADE ESPECIAL],
	ISNULL([SIMPRO SINTAE].VALORSIMPROSINTAE,0) AS [SIMPRO/SINTAE],
	ISNULL([FIES].VALORFIES,0) AS [FIES],
	ISNULL([RECOMECAR].VALORRECOMECAR,0) AS [RECOMECAR],

	CASE WHEN (
		([GRATUIDADE].VALORGRATUIDADE IS NOT NULL OR [GRATUIDADE].VALORGRATUIDADE <> 0) OR
		([GRATUIDADE ESPECIAL].VALORGRATUIDADEESP IS NOT NULL OR [GRATUIDADE ESPECIAL].VALORGRATUIDADEESP <> 0) OR
  		([RECOMECAR].VALORRECOMECAR IS NOT NULL OR [RECOMECAR].VALORRECOMECAR <> 0)
	) 
	THEN 
		M.VALORORIGINAL - ISNULL([GRATUIDADE].VALORGRATUIDADE,0) - ISNULL([GRATUIDADE ESPECIAL].VALORGRATUIDADEESP,0) - ISNULL([RECOMECAR].VALORRECOMECAR,0) - ISNULL([SIMPRO SINTAE].VALORSIMPROSINTAE,0)
	ELSE 0 END AS [TOTAL A PAGAR]
	
FROM 
	SMATRICPL AS A (NOLOCK) 
	LEFT JOIN SSTATUS AS A1 (NOLOCK) ON
		A1.CODSTATUS = A.CODSTATUS
	LEFT JOIN SSTATUS AS A2 (NOLOCK) ON
		A2.CODSTATUS = A.CODSTATUSRES
	LEFT JOIN SALUNO AS B (NOLOCK) ON
		A.CODCOLIGADA = B.CODCOLIGADA
		AND A.RA = B.RA
	LEFT JOIN PPESSOA AS C (NOLOCK) ON
		B.CODPESSOA = C.CODIGO
	LEFT JOIN SHABILITACAOALUNO AS D (NOLOCK) ON
		A.CODCOLIGADA = D.CODCOLIGADA
		AND A.IDHABILITACAOFILIAL = D.IDHABILITACAOFILIAL
		AND A.RA = D.RA
	LEFT JOIN SHABILITACAOFILIAL AS E (NOLOCK) ON
		D.CODCOLIGADA = E.CODCOLIGADA
		AND D.IDHABILITACAOFILIAL = E.IDHABILITACAOFILIAL
	LEFT JOIN SGRADE AS F (NOLOCK) ON
		E.CODCOLIGADA = F.CODCOLIGADA
		AND E.CODCURSO = F.CODCURSO
		AND E.CODHABILITACAO = F.CODHABILITACAO
		AND E.CODGRADE = F.CODGRADE
	LEFT JOIN SHABILITACAO AS G (NOLOCK) ON
		F.CODCOLIGADA = G.CODCOLIGADA
		AND F.CODCURSO = G.CODCURSO
		AND F.CODHABILITACAO = G.CODHABILITACAO
	LEFT JOIN SCURSO AS H (NOLOCK) ON
		G.CODCOLIGADA = H.CODCOLIGADA
		AND G.CODCURSO = H.CODCURSO
	LEFT JOIN SCONTRATO AS I (NOLOCK) ON
		A.CODCOLIGADA = I.CODCOLIGADA
		AND A.IDPERLET = I.IDPERLET
		AND A.IDHABILITACAOFILIAL = I.IDHABILITACAOFILIAL
		AND A.RA = I.RA
	LEFT JOIN SPARCELA AS J (NOLOCK) ON
		I.CODCOLIGADA = J.CODCOLIGADA
		AND I.RA = J.RA
		AND I.CODCONTRATO = J.CODCONTRATO
		AND I.IDPERLET = J.IDPERLET
	LEFT JOIN SPLETIVO AS K (NOLOCK) ON
		A.IDPERLET = K.IDPERLET

	LEFT JOIN SLAN AS L (NOLOCK) ON
		J.CODCOLIGADA = L.CODCOLIGADA
		AND J.IDPARCELA = L.IDPARCELA

	LEFT JOIN FLAN AS M (NOLOCK) ON
		L.CODCOLIGADA = M.CODCOLIGADA
		AND L.IDLAN = M.IDLAN
	
	LEFT JOIN (
		SELECT 
			SBOLSALAN.CODCOLIGADA,
			SBOLSALAN.IDPARCELA,
			SBOLSALAN.IDLAN,
			SBOLSALAN.IDPERLET,
			SUM(SBOLSALAN.VALOR) AS VALORGRATUIDADE,
			CASE WHEN SUM(SBOLSALAN.VALOR) <> 0 THEN 1 ELSE 0 END AS [CONTA GRATUIDADE]
		FROM 
			SBOLSALAN (NOLOCK) 
		WHERE 
			SBOLSALAN.CODBOLSA IN (22,4,28,29,24,25)
		GROUP BY 
			SBOLSALAN.CODCOLIGADA,
			SBOLSALAN.IDPARCELA,
			SBOLSALAN.IDLAN,
			SBOLSALAN.IDPERLET
	) AS [GRATUIDADE] ON
		GRATUIDADE.CODCOLIGADA = A.CODCOLIGADA
		AND GRATUIDADE.IDLAN = M.IDLAN
		AND GRATUIDADE.IDPARCELA = J.IDPARCELA
		AND GRATUIDADE.IDPERLET = A.IDPERLET
	
	LEFT JOIN (
		SELECT 
			SBOLSALAN.CODCOLIGADA,
			SBOLSALAN.IDPARCELA,
			SBOLSALAN.IDLAN,
			SBOLSALAN.IDPERLET,
			SUM(SBOLSALAN.VALOR) AS VALORGRATUIDADEESP,
			CASE WHEN SUM(SBOLSALAN.VALOR) <> 0 THEN 1 ELSE 0 END AS [CONTA GRATUIDADE ESPECIAL]
		FROM 
			SBOLSALAN (NOLOCK) 
			LEFT JOIN SBOLSA (NOLOCK) ON
				SBOLSALAN.CODBOLSA = SBOLSA.CODBOLSA		
		WHERE 
			SBOLSALAN.CODBOLSA NOT IN (22,4,2,12,28,29,24,25,20,31,32,27,36) 
			AND SBOLSA.VALIDADELIMITADA = 0 
		GROUP BY 
			SBOLSALAN.CODCOLIGADA,
			SBOLSALAN.IDPARCELA,
			SBOLSALAN.IDLAN,
			SBOLSALAN.IDPERLET
	) AS [GRATUIDADE ESPECIAL] ON 
		[GRATUIDADE ESPECIAL].CODCOLIGADA = A.CODCOLIGADA
		AND [GRATUIDADE ESPECIAL].IDLAN = M.IDLAN
		AND [GRATUIDADE ESPECIAL].IDPARCELA = J.IDPARCELA
		AND [GRATUIDADE ESPECIAL].IDPERLET = A.IDPERLET

	LEFT JOIN (
		SELECT 
			SBOLSALAN.CODCOLIGADA,
			SBOLSALAN.IDPARCELA,
			SBOLSALAN.IDLAN,
			SBOLSALAN.IDPERLET,
			SUM(SBOLSALAN.VALOR) AS VALORGRATUIDADEPARCIAL,
			CASE WHEN SUM(SBOLSALAN.VALOR) <> 0 THEN 1 ELSE 0 END AS [CONTA GRATUIDADE PARCIAL]
		FROM 
			SBOLSALAN (NOLOCK) 
		WHERE 
			SBOLSALAN.CODBOLSA IN (4,28,24)
		GROUP BY 
			SBOLSALAN.CODCOLIGADA,
			SBOLSALAN.IDPARCELA,
			SBOLSALAN.IDLAN,
			SBOLSALAN.IDPERLET
	) AS [GRATUIDADE PARCIAL] ON
		[GRATUIDADE PARCIAL].CODCOLIGADA = A.CODCOLIGADA
		AND [GRATUIDADE PARCIAL].IDLAN = M.IDLAN
		AND [GRATUIDADE PARCIAL].IDPARCELA = J.IDPARCELA
		AND [GRATUIDADE PARCIAL].IDPERLET = A.IDPERLET

	LEFT JOIN (
		SELECT 
			SBOLSALAN.CODCOLIGADA,
			SBOLSALAN.IDPARCELA,
			SBOLSALAN.IDLAN,
			SBOLSALAN.IDPERLET,
			SUM(SBOLSALAN.VALOR) AS VALORGRATUIDADETOTAL,
			CASE WHEN SUM(SBOLSALAN.VALOR) <> 0 THEN 1 ELSE 0 END AS [CONTA GRATUIDADE TOTAL]
		FROM 
			SBOLSALAN (NOLOCK) 
		WHERE 
			SBOLSALAN.CODBOLSA IN (22,29,25)
		GROUP BY 
			SBOLSALAN.CODCOLIGADA,
			SBOLSALAN.IDPARCELA,
			SBOLSALAN.IDLAN,
			SBOLSALAN.IDPERLET
	) AS [GRATUIDADE TOTAL] ON
		[GRATUIDADE TOTAL].CODCOLIGADA = A.CODCOLIGADA
		AND [GRATUIDADE TOTAL].IDLAN = M.IDLAN
		AND [GRATUIDADE TOTAL].IDPARCELA = J.IDPARCELA
		AND [GRATUIDADE TOTAL].IDPERLET = A.IDPERLET

	LEFT JOIN (
		SELECT 
			SBOLSALAN.CODCOLIGADA,
			SBOLSALAN.IDPARCELA,
			SBOLSALAN.IDLAN,
			SBOLSALAN.IDPERLET,
			SUM(SBOLSALAN.VALOR) AS VALORRECOMECAR,
			CASE WHEN SUM(SBOLSALAN.VALOR) <> 0 THEN 1 ELSE 0 END AS [CONTA RECOMECAR]
		FROM 
			SBOLSALAN (NOLOCK) 
		WHERE 
			SBOLSALAN.CODBOLSA IN (12)
		GROUP BY 
			SBOLSALAN.CODCOLIGADA,
			SBOLSALAN.IDPARCELA,
			SBOLSALAN.IDLAN,
			SBOLSALAN.IDPERLET
	) AS [RECOMECAR] ON
		RECOMECAR.CODCOLIGADA = A.CODCOLIGADA
		AND RECOMECAR.IDLAN = M.IDLAN
		AND RECOMECAR.IDPARCELA = J.IDPARCELA
		AND RECOMECAR.IDPERLET = A.IDPERLET
	
	LEFT JOIN (
		SELECT 
			SBOLSALAN.CODCOLIGADA,
			SBOLSALAN.IDPARCELA,
			SBOLSALAN.IDLAN,
			SBOLSALAN.IDPERLET,
			SUM(SBOLSALAN.VALOR) AS VALORFIES,
			CASE WHEN SUM(SBOLSALAN.VALOR) <> 0 THEN 1 ELSE 0 END AS [CONTA FIES]
		FROM 
			SBOLSALAN (NOLOCK) 
			LEFT JOIN FLAN (NOLOCK) ON 
				FLAN.IDLAN = SBOLSALAN.IDLAN
		WHERE 
			SBOLSALAN.CODBOLSA IN (2)
		GROUP BY 
			SBOLSALAN.CODCOLIGADA,
			SBOLSALAN.IDPARCELA,
			SBOLSALAN.IDLAN,
			SBOLSALAN.IDPERLET
	) AS [FIES] ON
		FIES.CODCOLIGADA = A.CODCOLIGADA
		AND FIES.IDLAN = M.IDLAN
		AND FIES.IDPARCELA = J.IDPARCELA
		AND FIES.IDPERLET = A.IDPERLET

	LEFT JOIN (
		SELECT 
			SBOLSALAN.CODCOLIGADA,
			SBOLSALAN.IDPARCELA,
			SBOLSALAN.IDLAN,
			SBOLSALAN.IDPERLET,
			SUM(SBOLSALAN.VALOR) AS VALORSIMPROSINTAE,
			CASE WHEN SUM(SBOLSALAN.VALOR) <> 0 THEN 1 ELSE 0 END AS [CONTA SIMPRO SINTAE]
		FROM 
			SBOLSALAN (NOLOCK) 
			LEFT JOIN FLAN (NOLOCK) ON 
				FLAN.IDLAN = SBOLSALAN.IDLAN
		WHERE 
			SBOLSALAN.CODBOLSA IN (20,31,32,27,36)
		GROUP BY 
			SBOLSALAN.CODCOLIGADA,
			SBOLSALAN.IDPARCELA,
			SBOLSALAN.IDLAN,
			SBOLSALAN.IDPERLET
	) AS [SIMPRO SINTAE] ON
		[SIMPRO SINTAE].CODCOLIGADA = A.CODCOLIGADA
		AND [SIMPRO SINTAE].IDLAN = M.IDLAN
		AND [SIMPRO SINTAE].IDPARCELA = J.IDPARCELA
		AND [SIMPRO SINTAE].IDPERLET = A.IDPERLET	
WHERE 
		M.STATUSLAN = 0
	AND A.CODFILIAL = @CODFILIAL
	--AND K.CODPERLET = '2015.2'
	AND M.DATAVENCIMENTO < @DTVENCIMENTO
