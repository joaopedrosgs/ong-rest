/*
Grupo:

João Pedro São Gregorio Silva, 726549
Alisson Hayasi, 726494

--------------------------------------------------------------------------------

Resultado dos EXPLAIN:
SELECT p.nome, a.alergia from beneficiario b, alergias a, pessoa p where p.cpf = b.cpf_pessoa and a.cpf_beneficiario = b.cpf_pessoa;
sem indexes:
Hash Join  (cost=8.14..10.17 rows=31 width=133)
  Hash Cond: ((b.cpf_pessoa)::text = (p.cpf)::text)
  ->  Seq Scan on beneficiario b  (cost=0.00..1.67 rows=67 width=12)
  ->  Hash  (cost=7.76..7.76 rows=31 width=185)
        ->  Hash Join  (cost=1.70..7.76 rows=31 width=185)
              Hash Cond: ((p.cpf)::text = (a.cpf_beneficiario)::text)
              ->  Seq Scan on pessoa p  (cost=0.00..5.00 rows=200 width=27)
              ->  Hash  (cost=1.31..1.31 rows=31 width=158)
                    ->  Seq Scan on alergias a  (cost=0.00..1.31 rows=31 width=158)

Com indexes:
Hash Join  (cost=4.21..10.09 rows=31 width=133)
  Hash Cond: ((p.cpf)::text = (a.cpf_beneficiario)::text)
  ->  Hash Join  (cost=2.51..8.04 rows=67 width=39)
        Hash Cond: ((p.cpf)::text = (b.cpf_pessoa)::text)
        ->  Seq Scan on pessoa p  (cost=0.00..5.00 rows=200 width=27)
        ->  Hash  (cost=1.67..1.67 rows=67 width=12)
              ->  Seq Scan on beneficiario b  (cost=0.00..1.67 rows=67 width=12)
  ->  Hash  (cost=1.31..1.31 rows=31 width=158)
        ->  Seq Scan on alergias a  (cost=0.00..1.31 rows=31 width=158)


Comentario: Podemos ver que a grande diferença entre os dois se deve muito ao fato de que, sem index no beneficiario, o postgres tem que fazer uma busca sequencial, o que é muito lento
        
--------------------------------------------------------------------------------------

SELECT p.nome, b.cpf_pessoa, o.nome from beneficiario b, pessoa p, beneficiario_participa_ong bpo, ong o where p.cpf = b.cpf_pessoa and b.cpf_pessoa=bpo.cpf_beneficiario and bpo.codigo_ong=o.codigo
Sem indexes:
Hash Join  (cost=11.31..14.07 rows=27 width=145)
  Hash Cond: (bpo.codigo_ong = o.codigo)
  ->  Hash Join  (cost=9.77..12.16 rows=27 width=31)
        Hash Cond: ((bpo.cpf_beneficiario)::text = (p.cpf)::text)
        ->  Seq Scan on beneficiario_participa_ong bpo  (cost=0.00..1.82 rows=82 width=16)
        ->  Hash  (cost=8.93..8.93 rows=67 width=39)
              ->  Hash Join  (cost=2.51..8.93 rows=67 width=39)
                    Hash Cond: ((p.cpf)::text = (b.cpf_pessoa)::text)
                    ->  Seq Scan on pessoa p  (cost=0.00..5.00 rows=200 width=27)
                    ->  Hash  (cost=1.67..1.67 rows=67 width=12)
                          ->  Seq Scan on beneficiario b  (cost=0.00..1.67 rows=67 width=12)
  ->  Hash  (cost=1.24..1.24 rows=24 width=122)
        ->  Seq Scan on ong o  (cost=0.00..1.24 rows=24 width=122)
Com indexes: 
Hash Join  (cost=10.42..13.07 rows=82 width=145)
  Hash Cond: (bpo.codigo_ong = o.codigo)
  ->  Hash Join  (cost=8.88..11.28 rows=82 width=31)
        Hash Cond: ((bpo.cpf_beneficiario)::text = (p.cpf)::text)
        ->  Seq Scan on beneficiario_participa_ong bpo  (cost=0.00..1.82 rows=82 width=16)
        ->  Hash  (cost=8.04..8.04 rows=67 width=39)
              ->  Hash Join  (cost=2.51..8.04 rows=67 width=39)
                    Hash Cond: ((p.cpf)::text = (b.cpf_pessoa)::text)
                    ->  Seq Scan on pessoa p  (cost=0.00..5.00 rows=200 width=27)
                    ->  Hash  (cost=1.67..1.67 rows=67 width=12)
                          ->  Seq Scan on beneficiario b  (cost=0.00..1.67 rows=67 width=12)
  ->  Hash  (cost=1.24..1.24 rows=24 width=122)
        ->  Seq Scan on ong o  (cost=0.00..1.24 rows=24 width=122)

Comentario: Aqui as duas buscas possuem praticamente o mesmo tempo de execução, mas podemos ver que com indexes o pg visitou 83 rows, e mesmo assim ainda foi mais rapido que sem index (que visitou apenas 27)
provavelmente foi apenas coincidencia

-----------------------------------------------------------------------------

SELECT p.nome, b.cpf_pessoa, (select nome from pessoa where cpf = cpf_voluntario_responsavel) from beneficiario b, pessoa p, beneficiario_participa_ong bpo, ong o where p.cpf = b.cpf_pessoa and b.cpf_pessoa=bpo.cpf_beneficiario and bpo.codigo_ong=o.codigo;

Sem indexes: 
Hash Join  (cost=11.31..162.57 rows=27 width=145)
  Hash Cond: (bpo.codigo_ong = o.codigo)
  ->  Hash Join  (cost=9.77..12.16 rows=27 width=31)
        Hash Cond: ((bpo.cpf_beneficiario)::text = (p.cpf)::text)
        ->  Seq Scan on beneficiario_participa_ong bpo  (cost=0.00..1.82 rows=82 width=16)
        ->  Hash  (cost=8.93..8.93 rows=67 width=39)
              ->  Hash Join  (cost=2.51..8.93 rows=67 width=39)
                    Hash Cond: ((p.cpf)::text = (b.cpf_pessoa)::text)
                    ->  Seq Scan on pessoa p  (cost=0.00..5.00 rows=200 width=27)
                    ->  Hash  (cost=1.67..1.67 rows=67 width=12)
                          ->  Seq Scan on beneficiario b  (cost=0.00..1.67 rows=67 width=12)
  ->  Hash  (cost=1.24..1.24 rows=24 width=44)
        ->  Seq Scan on ong o  (cost=0.00..1.24 rows=24 width=44)
  SubPlan 1
    ->  Seq Scan on pessoa  (cost=0.00..5.50 rows=1 width=15)
          Filter: ((cpf)::text = (o.cpf_voluntario_responsavel)::text)

Com indexes:
Hash Join  (cost=10.42..464.07 rows=82 width=145)
  Hash Cond: (bpo.codigo_ong = o.codigo)
  ->  Hash Join  (cost=8.88..11.28 rows=82 width=31)
        Hash Cond: ((bpo.cpf_beneficiario)::text = (p.cpf)::text)
        ->  Seq Scan on beneficiario_participa_ong bpo  (cost=0.00..1.82 rows=82 width=16)
        ->  Hash  (cost=8.04..8.04 rows=67 width=39)
              ->  Hash Join  (cost=2.51..8.04 rows=67 width=39)
                    Hash Cond: ((p.cpf)::text = (b.cpf_pessoa)::text)
                    ->  Seq Scan on pessoa p  (cost=0.00..5.00 rows=200 width=27)
                    ->  Hash  (cost=1.67..1.67 rows=67 width=12)
                          ->  Seq Scan on beneficiario b  (cost=0.00..1.67 rows=67 width=12)
  ->  Hash  (cost=1.24..1.24 rows=24 width=44)
        ->  Seq Scan on ong o  (cost=0.00..1.24 rows=24 width=44)
  SubPlan 1
    ->  Seq Scan on pessoa  (cost=0.00..5.50 rows=1 width=15)
          Filter: ((cpf)::text = (o.cpf_voluntario_responsavel)::text)

Comentario: por serem queries parecidas, aconteceu a mesma coisa que na busca acima



*/



--
-- PostgreSQL database dump
--

-- Dumped from database version 11.3
-- Dumped by pg_dump version 11.3


ALTER TABLE IF EXISTS ONLY public.voluntario_voluntaria_ong DROP CONSTRAINT IF EXISTS voluntario_voluntaria_ong_voluntario_cpf_pessoa_fk;
ALTER TABLE IF EXISTS ONLY public.voluntario_voluntaria_ong DROP CONSTRAINT IF EXISTS voluntario_voluntaria_ong_ong_codigo_fk;
ALTER TABLE IF EXISTS ONLY public.voluntario DROP CONSTRAINT IF EXISTS voluntario_pessoa_cpf_fk;
ALTER TABLE IF EXISTS ONLY public.ong DROP CONSTRAINT IF EXISTS ong_voluntario_cpf_pessoa_fk;
ALTER TABLE IF EXISTS ONLY public.log_beneficiario DROP CONSTRAINT IF EXISTS log_beneficiario_beneficiario_cpf_pessoa_fk;
ALTER TABLE IF EXISTS ONLY public.doacao DROP CONSTRAINT IF EXISTS doacao_pessoa_cpf_fk;
ALTER TABLE IF EXISTS ONLY public.doacao DROP CONSTRAINT IF EXISTS doacao_ong_codigo_fk;
ALTER TABLE IF EXISTS ONLY public.beneficiario_possui_responsavel DROP CONSTRAINT IF EXISTS beneficiario_possui_responsavel_pessoa_cpf_fk;
ALTER TABLE IF EXISTS ONLY public.beneficiario_possui_responsavel DROP CONSTRAINT IF EXISTS beneficiario_possui_responsavel_beneficiario_cpf_pessoa_fk;
ALTER TABLE IF EXISTS ONLY public.beneficiario DROP CONSTRAINT IF EXISTS beneficiario_pessoa_cpf_fk;
ALTER TABLE IF EXISTS ONLY public.beneficiario_participa_ong DROP CONSTRAINT IF EXISTS beneficiario_participa_ong_ong_codigo_fk;
ALTER TABLE IF EXISTS ONLY public.beneficiario_participa_ong DROP CONSTRAINT IF EXISTS beneficiario_participa_ong_beneficiario_cpf_pessoa_fk;
ALTER TABLE IF EXISTS ONLY public.alergias DROP CONSTRAINT IF EXISTS alergias_beneficiario_cpf_pessoa_fk;
DROP TRIGGER IF EXISTS saida_beneficiario ON public.beneficiario_participa_ong;
DROP TRIGGER IF EXISTS entrada_beneficiario ON public.beneficiario_participa_ong;
DROP INDEX IF EXISTS public.voluntario_cpf_pessoa_uindex;
DROP INDEX IF EXISTS public.pessoa_cpf_uindex;
DROP INDEX IF EXISTS public.ong_cpf_voluntario_responsavel_uindex;
DROP INDEX IF EXISTS public.ong_codigo_uindex;
DROP INDEX IF EXISTS public.log_beneficiario_id_uindex;
DROP INDEX IF EXISTS public.doacao_codigo_uindex;
DROP INDEX IF EXISTS public.beneficiario_cpf_pessoa_uindex;
ALTER TABLE IF EXISTS ONLY public.voluntario_voluntaria_ong DROP CONSTRAINT IF EXISTS voluntario_voluntaria_ong_pk;
ALTER TABLE IF EXISTS ONLY public.voluntario DROP CONSTRAINT IF EXISTS voluntario_pk;
ALTER TABLE IF EXISTS ONLY public.pessoa DROP CONSTRAINT IF EXISTS pessoa_pk;
ALTER TABLE IF EXISTS ONLY public.ong DROP CONSTRAINT IF EXISTS ong_pk;
ALTER TABLE IF EXISTS ONLY public.log_beneficiario DROP CONSTRAINT IF EXISTS log_beneficiario_pk;
ALTER TABLE IF EXISTS ONLY public.doacao DROP CONSTRAINT IF EXISTS doacao_pk;
ALTER TABLE IF EXISTS ONLY public.beneficiario_possui_responsavel DROP CONSTRAINT IF EXISTS beneficiario_possui_responsavel_pk;
ALTER TABLE IF EXISTS ONLY public.beneficiario DROP CONSTRAINT IF EXISTS beneficiario_pk;
ALTER TABLE IF EXISTS ONLY public.alergias DROP CONSTRAINT IF EXISTS alergias_pk;
ALTER TABLE IF EXISTS public.ong ALTER COLUMN codigo DROP DEFAULT;
ALTER TABLE IF EXISTS public.log_beneficiario ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.doacao ALTER COLUMN codigo DROP DEFAULT;
DROP TABLE IF EXISTS public.voluntario_voluntaria_ong;
DROP TABLE IF EXISTS public.voluntario;
DROP TABLE IF EXISTS public.pessoa;
DROP SEQUENCE IF EXISTS public.ong_codigo_seq;
DROP TABLE IF EXISTS public.ong;
DROP SEQUENCE IF EXISTS public.log_beneficiario_id_seq;
DROP TABLE IF EXISTS public.log_beneficiario;
DROP SEQUENCE IF EXISTS public.doacao_codigo_seq;
DROP TABLE IF EXISTS public.doacao;
DROP TABLE IF EXISTS public.beneficiario_possui_responsavel;
DROP TABLE IF EXISTS public.beneficiario_participa_ong;
DROP TABLE IF EXISTS public.beneficiario;
DROP TABLE IF EXISTS public.alergias;
DROP FUNCTION IF EXISTS public.total_doacoes_pessoa(cpfalvo character varying);
DROP FUNCTION IF EXISTS public.total_doacoes(code integer);
DROP FUNCTION IF EXISTS public.log_saida_beneficiario();
DROP FUNCTION IF EXISTS public.log_entrada_beneficiario();
DROP FUNCTION IF EXISTS public.inserevoluntario(cpf_voluntario character varying, nome_voluntario character varying);
DROP FUNCTION IF EXISTS public.inserebeneficiario(cpf_beneficiario character varying, nome_beneficiario character varying);


--
-- Name: inserebeneficiario(character varying, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.inserebeneficiario(cpf_beneficiario character varying, nome_beneficiario character varying) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    INSERT INTO pessoa (cpf, nome) VALUES (cpf_beneficiario, nome_beneficiario) ON CONFLICT DO NOTHING ;
	INSERT INTO beneficiario (cpf_pessoa) VALUES (cpf_beneficiario);
END;

$$;


--
-- Name: inserevoluntario(character varying, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.inserevoluntario(cpf_voluntario character varying, nome_voluntario character varying) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    INSERT INTO pessoa (cpf, nome) VALUES (cpf_voluntario, nome_voluntario) ON CONFLICT DO NOTHING ;
	INSERT INTO voluntario (cpf_pessoa) VALUES (cpf_voluntario);
END;

$$;


--
-- Name: log_entrada_beneficiario(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.log_entrada_beneficiario() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
   		INSERT INTO log_beneficiario(cpf_beneficiario, acao)  VALUES(NEW.cpf_beneficiario,'entrada_ong');
   RETURN NEW;
END;

$$;


--
-- Name: log_saida_beneficiario(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.log_saida_beneficiario() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
   		INSERT INTO log_beneficiario(cpf_beneficiario, acao)  VALUES(OLD.cpf_beneficiario,'saida_ong');
   RETURN NEW;
END;

$$;


--
-- Name: total_doacoes(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.total_doacoes(code integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE total INTEGER;
	BEGIN select sum(d.valor) into total from doacao d, ong o
						where d.codigo_ong = o.codigo and
							o.codigo = Code;
		RETURN total;
	END;
$$;


--
-- Name: total_doacoes_pessoa(character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.total_doacoes_pessoa(cpfalvo character varying) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE total INTEGER;
	BEGIN
		select sum(doacao.valor) into total from pessoa, doacao
			where pessoa.cpf = doacao.cpf_pessoa
				and pessoa.cpf LIKE CPFALVO;
		RETURN total;
	END;
	
$$;


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: alergias; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.alergias (
    cpf_beneficiario character varying(11) NOT NULL,
    alergia character varying(50) NOT NULL,
    remedio character varying(50) NOT NULL
);


--
-- Name: beneficiario; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.beneficiario (
    cpf_pessoa character varying(11) NOT NULL
);


--
-- Name: beneficiario_participa_ong; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.beneficiario_participa_ong (
    cpf_beneficiario character varying(11) NOT NULL,
    codigo_ong integer NOT NULL,
    data_inicio timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: beneficiario_possui_responsavel; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.beneficiario_possui_responsavel (
    cpf_pessoa character varying(11) NOT NULL,
    cpf_beneficiario character varying(11) NOT NULL
);


--
-- Name: doacao; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.doacao (
    cpf_pessoa character varying(11) NOT NULL,
    codigo_ong integer NOT NULL,
    codigo integer NOT NULL,
    tipo character varying(50) NOT NULL,
    valor integer DEFAULT 0 NOT NULL,
    data timestamp without time zone NOT NULL
);


--
-- Name: doacao_codigo_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.doacao_codigo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: doacao_codigo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.doacao_codigo_seq OWNED BY public.doacao.codigo;


--
-- Name: log_beneficiario; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.log_beneficiario (
    id integer NOT NULL,
    cpf_beneficiario character varying(20),
    acao character varying(20),
    data timestamp without time zone DEFAULT now()
);


--
-- Name: log_beneficiario_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.log_beneficiario_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: log_beneficiario_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.log_beneficiario_id_seq OWNED BY public.log_beneficiario.id;


--
-- Name: ong; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ong (
    nome character varying(50) NOT NULL,
    codigo integer NOT NULL,
    rua character varying(50) NOT NULL,
    bairro character varying(50) NOT NULL,
    cep integer NOT NULL,
    numero integer NOT NULL,
    cpf_voluntario_responsavel character varying(11),
    cidade character varying(50) NOT NULL
);


--
-- Name: ong_codigo_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ong_codigo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ong_codigo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ong_codigo_seq OWNED BY public.ong.codigo;


--
-- Name: pessoa; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.pessoa (
    nome character varying(50) NOT NULL,
    cpf character varying(11) NOT NULL,
    rua character varying(50),
    nro integer,
    bairro character varying(50),
    cidade character varying(50),
    cep integer,
    telefone character varying(14)
);


--
-- Name: voluntario; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.voluntario (
    cpf_pessoa character varying(11) NOT NULL
);


--
-- Name: voluntario_voluntaria_ong; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.voluntario_voluntaria_ong (
    cpf_voluntario character varying(11) NOT NULL,
    codigo_ong integer NOT NULL,
    inicio timestamp without time zone DEFAULT now() NOT NULL
);


--
-- Name: doacao codigo; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.doacao ALTER COLUMN codigo SET DEFAULT nextval('public.doacao_codigo_seq'::regclass);


--
-- Name: log_beneficiario id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.log_beneficiario ALTER COLUMN id SET DEFAULT nextval('public.log_beneficiario_id_seq'::regclass);


--
-- Name: ong codigo; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ong ALTER COLUMN codigo SET DEFAULT nextval('public.ong_codigo_seq'::regclass);


--
-- Data for Name: alergias; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.alergias VALUES ('31939735834', 'Doenca', 'Remedio');
INSERT INTO public.alergias VALUES ('11092374501', 'Doenca2', 'Remedio2');
INSERT INTO public.alergias VALUES ('25566799567', 'Doenca3', 'Remedio3');
INSERT INTO public.alergias VALUES ('12741896242', 'Doenca3', 'Remedio4');
INSERT INTO public.alergias VALUES ('10663247031', 'Doenca2', 'Remedio4');
INSERT INTO public.alergias VALUES ('39868526020', 'Doenca5', 'Remedio7');
INSERT INTO public.alergias VALUES ('21673025963', 'Doenca5', 'Remedio7');
INSERT INTO public.alergias VALUES ('18900426507', 'Doenca5', 'Remedio7');
INSERT INTO public.alergias VALUES ('12741896242', 'Doenca5', 'Remedio7');
INSERT INTO public.alergias VALUES ('10636339202', 'Doenca5', 'Remedio7');
INSERT INTO public.alergias VALUES ('20932011457', 'Doenca5', 'Remedio7');
INSERT INTO public.alergias VALUES ('14152184374', 'Doenca5', 'Remedio7');
INSERT INTO public.alergias VALUES ('40996997281', 'Doenca5', 'Remedio7');
INSERT INTO public.alergias VALUES ('18733143087', 'Doenca5', 'Remedio7');
INSERT INTO public.alergias VALUES ('24507530690', 'Doenca5', 'Remedio7');
INSERT INTO public.alergias VALUES ('30649836503', 'Doenca5', 'Remedio7');
INSERT INTO public.alergias VALUES ('37259632003', 'Doenca5', 'Remedio7');
INSERT INTO public.alergias VALUES ('25566799567', 'Doenca5', 'Remedio7');
INSERT INTO public.alergias VALUES ('11597795854', 'Doenca5', 'Remedio7');
INSERT INTO public.alergias VALUES ('25591291736', 'Doenca5', 'Remedio7');
INSERT INTO public.alergias VALUES ('15808041190', 'Doenca5', 'Remedio7');
INSERT INTO public.alergias VALUES ('19315290560', 'Doenca5', 'Remedio7');
INSERT INTO public.alergias VALUES ('11092374501', 'Doenca5', 'Remedio7');
INSERT INTO public.alergias VALUES ('31132589299', 'Doenca5', 'Remedio7');
INSERT INTO public.alergias VALUES ('35258402567', 'Doenca5', 'Remedio7');
INSERT INTO public.alergias VALUES ('48755879001', 'Doenca5', 'Remedio7');
INSERT INTO public.alergias VALUES ('42875993149', 'Doenca5', 'Remedio7');
INSERT INTO public.alergias VALUES ('42908169240', 'Doenca5', 'Remedio7');
INSERT INTO public.alergias VALUES ('37183007160', 'Doenca5', 'Remedio7');
INSERT INTO public.alergias VALUES ('23735466932', 'Doenca5', 'Remedio7');
INSERT INTO public.alergias VALUES ('44992088462', 'Doenca5', 'Remedio7');


--
-- Data for Name: beneficiario; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.beneficiario VALUES ('41235624635');
INSERT INTO public.beneficiario VALUES ('40996997281');
INSERT INTO public.beneficiario VALUES ('35780054230');
INSERT INTO public.beneficiario VALUES ('30518186547');
INSERT INTO public.beneficiario VALUES ('42908169240');
INSERT INTO public.beneficiario VALUES ('30218927780');
INSERT INTO public.beneficiario VALUES ('32124981347');
INSERT INTO public.beneficiario VALUES ('44482700459');
INSERT INTO public.beneficiario VALUES ('37183007160');
INSERT INTO public.beneficiario VALUES ('16464979798');
INSERT INTO public.beneficiario VALUES ('36567329970');
INSERT INTO public.beneficiario VALUES ('10636339202');
INSERT INTO public.beneficiario VALUES ('28142896319');
INSERT INTO public.beneficiario VALUES ('48650595784');
INSERT INTO public.beneficiario VALUES ('23735466932');
INSERT INTO public.beneficiario VALUES ('18733143087');
INSERT INTO public.beneficiario VALUES ('26971137510');
INSERT INTO public.beneficiario VALUES ('44029404634');
INSERT INTO public.beneficiario VALUES ('37245436669');
INSERT INTO public.beneficiario VALUES ('46943142992');
INSERT INTO public.beneficiario VALUES ('10663247031');
INSERT INTO public.beneficiario VALUES ('28202903636');
INSERT INTO public.beneficiario VALUES ('31132589299');
INSERT INTO public.beneficiario VALUES ('42875993149');
INSERT INTO public.beneficiario VALUES ('19315290560');
INSERT INTO public.beneficiario VALUES ('26585095594');
INSERT INTO public.beneficiario VALUES ('35258402567');
INSERT INTO public.beneficiario VALUES ('18474973323');
INSERT INTO public.beneficiario VALUES ('48755879001');
INSERT INTO public.beneficiario VALUES ('11463362049');
INSERT INTO public.beneficiario VALUES ('11092374501');
INSERT INTO public.beneficiario VALUES ('31401952347');
INSERT INTO public.beneficiario VALUES ('21673025963');
INSERT INTO public.beneficiario VALUES ('25591291736');
INSERT INTO public.beneficiario VALUES ('33203427206');
INSERT INTO public.beneficiario VALUES ('40181557129');
INSERT INTO public.beneficiario VALUES ('39868526020');
INSERT INTO public.beneficiario VALUES ('11597795854');
INSERT INTO public.beneficiario VALUES ('20932011457');
INSERT INTO public.beneficiario VALUES ('28275363183');
INSERT INTO public.beneficiario VALUES ('44992088462');
INSERT INTO public.beneficiario VALUES ('12741896242');
INSERT INTO public.beneficiario VALUES ('43103050722');
INSERT INTO public.beneficiario VALUES ('18900426507');
INSERT INTO public.beneficiario VALUES ('10292218291');
INSERT INTO public.beneficiario VALUES ('40817856515');
INSERT INTO public.beneficiario VALUES ('16183960173');
INSERT INTO public.beneficiario VALUES ('20526735932');
INSERT INTO public.beneficiario VALUES ('30649836503');
INSERT INTO public.beneficiario VALUES ('42981337365');
INSERT INTO public.beneficiario VALUES ('24507530690');
INSERT INTO public.beneficiario VALUES ('12230306633');
INSERT INTO public.beneficiario VALUES ('37259632003');
INSERT INTO public.beneficiario VALUES ('14152184374');
INSERT INTO public.beneficiario VALUES ('25566799567');
INSERT INTO public.beneficiario VALUES ('31939735834');
INSERT INTO public.beneficiario VALUES ('48674433818');
INSERT INTO public.beneficiario VALUES ('20458012821');
INSERT INTO public.beneficiario VALUES ('14537734037');
INSERT INTO public.beneficiario VALUES ('15808041190');
INSERT INTO public.beneficiario VALUES ('44235351721');
INSERT INTO public.beneficiario VALUES ('46499914772');
INSERT INTO public.beneficiario VALUES ('26304019532');
INSERT INTO public.beneficiario VALUES ('32033625198');
INSERT INTO public.beneficiario VALUES ('33259510731');
INSERT INTO public.beneficiario VALUES ('17416229636');
INSERT INTO public.beneficiario VALUES ('19359206243');


--
-- Data for Name: beneficiario_participa_ong; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.beneficiario_participa_ong VALUES ('30518186547', 1, '2019-05-17 00:01:14.955597');
INSERT INTO public.beneficiario_participa_ong VALUES ('33203427206', 1, '2019-05-17 00:01:15.600278');
INSERT INTO public.beneficiario_participa_ong VALUES ('18474973323', 1, '2019-05-17 00:01:16.264308');
INSERT INTO public.beneficiario_participa_ong VALUES ('37259632003', 1, '2019-05-17 00:01:16.536229');
INSERT INTO public.beneficiario_participa_ong VALUES ('19315290560', 1, '2019-05-17 00:01:16.718221');
INSERT INTO public.beneficiario_participa_ong VALUES ('12741896242', 1, '2019-05-17 00:01:16.87357');
INSERT INTO public.beneficiario_participa_ong VALUES ('25566799567', 1, '2019-05-17 00:01:17.036901');
INSERT INTO public.beneficiario_participa_ong VALUES ('28275363183', 2, '2019-05-17 00:01:49.54837');
INSERT INTO public.beneficiario_participa_ong VALUES ('31132589299', 2, '2019-05-17 00:01:49.724728');
INSERT INTO public.beneficiario_participa_ong VALUES ('37245436669', 2, '2019-05-17 00:01:49.87397');
INSERT INTO public.beneficiario_participa_ong VALUES ('26971137510', 2, '2019-05-17 00:01:50.020685');
INSERT INTO public.beneficiario_participa_ong VALUES ('11092374501', 2, '2019-05-17 00:01:50.224271');
INSERT INTO public.beneficiario_participa_ong VALUES ('20526735932', 2, '2019-05-17 00:01:50.381808');
INSERT INTO public.beneficiario_participa_ong VALUES ('23735466932', 2, '2019-05-17 00:01:50.40868');
INSERT INTO public.beneficiario_participa_ong VALUES ('28275363183', 2, '2019-05-17 00:01:50.504592');
INSERT INTO public.beneficiario_participa_ong VALUES ('26971137510', 2, '2019-05-17 00:01:50.71188');
INSERT INTO public.beneficiario_participa_ong VALUES ('37245436669', 2, '2019-05-17 00:01:50.735968');
INSERT INTO public.beneficiario_participa_ong VALUES ('48650595784', 2, '2019-05-17 00:01:50.820055');
INSERT INTO public.beneficiario_participa_ong VALUES ('10292218291', 2, '2019-05-17 00:01:50.916215');
INSERT INTO public.beneficiario_participa_ong VALUES ('36567329970', 2, '2019-05-17 00:01:51.029321');
INSERT INTO public.beneficiario_participa_ong VALUES ('20932011457', 2, '2019-05-17 00:01:51.152159');
INSERT INTO public.beneficiario_participa_ong VALUES ('26585095594', 2, '2019-05-17 00:01:51.250216');
INSERT INTO public.beneficiario_participa_ong VALUES ('30218927780', 2, '2019-05-17 00:01:51.378835');
INSERT INTO public.beneficiario_participa_ong VALUES ('48674433818', 2, '2019-05-17 00:01:51.469774');
INSERT INTO public.beneficiario_participa_ong VALUES ('14537734037', 2, '2019-05-17 00:01:51.585807');
INSERT INTO public.beneficiario_participa_ong VALUES ('21673025963', 2, '2019-05-17 00:01:51.676358');
INSERT INTO public.beneficiario_participa_ong VALUES ('48674433818', 2, '2019-05-17 00:01:51.766177');
INSERT INTO public.beneficiario_participa_ong VALUES ('44029404634', 2, '2019-05-17 00:01:51.869952');
INSERT INTO public.beneficiario_participa_ong VALUES ('21673025963', 2, '2019-05-17 00:01:51.977999');
INSERT INTO public.beneficiario_participa_ong VALUES ('26585095594', 2, '2019-05-17 00:01:52.074879');
INSERT INTO public.beneficiario_participa_ong VALUES ('20458012821', 2, '2019-05-17 00:01:52.168447');
INSERT INTO public.beneficiario_participa_ong VALUES ('40817856515', 2, '2019-05-17 00:01:52.26591');
INSERT INTO public.beneficiario_participa_ong VALUES ('23735466932', 2, '2019-05-17 00:01:52.392275');
INSERT INTO public.beneficiario_participa_ong VALUES ('11597795854', 2, '2019-05-17 00:01:52.45961');
INSERT INTO public.beneficiario_participa_ong VALUES ('42875993149', 2, '2019-05-17 00:01:52.580716');
INSERT INTO public.beneficiario_participa_ong VALUES ('16183960173', 2, '2019-05-17 00:01:52.671833');
INSERT INTO public.beneficiario_participa_ong VALUES ('40817856515', 3, '2019-05-17 00:01:58.184722');
INSERT INTO public.beneficiario_participa_ong VALUES ('14152184374', 3, '2019-05-17 00:01:58.276879');
INSERT INTO public.beneficiario_participa_ong VALUES ('26585095594', 3, '2019-05-17 00:01:58.378138');
INSERT INTO public.beneficiario_participa_ong VALUES ('44482700459', 3, '2019-05-17 00:01:58.497809');
INSERT INTO public.beneficiario_participa_ong VALUES ('10636339202', 3, '2019-05-17 00:01:58.617328');
INSERT INTO public.beneficiario_participa_ong VALUES ('43103050722', 3, '2019-05-17 00:01:58.746488');
INSERT INTO public.beneficiario_participa_ong VALUES ('20932011457', 3, '2019-05-17 00:01:58.829189');
INSERT INTO public.beneficiario_participa_ong VALUES ('14537734037', 3, '2019-05-17 00:01:58.940369');
INSERT INTO public.beneficiario_participa_ong VALUES ('48674433818', 3, '2019-05-17 00:01:59.051889');
INSERT INTO public.beneficiario_participa_ong VALUES ('37245436669', 3, '2019-05-17 00:01:59.182617');
INSERT INTO public.beneficiario_participa_ong VALUES ('18733143087', 3, '2019-05-17 00:01:59.307592');
INSERT INTO public.beneficiario_participa_ong VALUES ('18733143087', 3, '2019-05-17 00:01:59.413104');
INSERT INTO public.beneficiario_participa_ong VALUES ('21673025963', 3, '2019-05-17 00:01:59.51155');
INSERT INTO public.beneficiario_participa_ong VALUES ('41235624635', 3, '2019-05-17 00:01:59.633978');
INSERT INTO public.beneficiario_participa_ong VALUES ('26585095594', 3, '2019-05-17 00:01:59.758955');
INSERT INTO public.beneficiario_participa_ong VALUES ('36567329970', 3, '2019-05-17 00:01:59.852646');
INSERT INTO public.beneficiario_participa_ong VALUES ('35258402567', 3, '2019-05-17 00:01:59.963973');
INSERT INTO public.beneficiario_participa_ong VALUES ('31401952347', 3, '2019-05-17 00:02:00.280302');
INSERT INTO public.beneficiario_participa_ong VALUES ('32124981347', 3, '2019-05-17 00:02:00.379612');
INSERT INTO public.beneficiario_participa_ong VALUES ('19315290560', 3, '2019-05-17 00:02:00.492471');
INSERT INTO public.beneficiario_participa_ong VALUES ('30518186547', 3, '2019-05-17 00:02:00.610488');
INSERT INTO public.beneficiario_participa_ong VALUES ('30518186547', 3, '2019-05-17 00:02:00.716177');
INSERT INTO public.beneficiario_participa_ong VALUES ('43103050722', 3, '2019-05-17 00:02:00.819469');
INSERT INTO public.beneficiario_participa_ong VALUES ('39868526020', 3, '2019-05-17 00:02:00.91273');
INSERT INTO public.beneficiario_participa_ong VALUES ('11463362049', 3, '2019-05-17 00:02:01.156791');
INSERT INTO public.beneficiario_participa_ong VALUES ('44992088462', 3, '2019-05-17 00:02:01.265118');
INSERT INTO public.beneficiario_participa_ong VALUES ('28202903636', 3, '2019-05-17 00:02:01.390938');
INSERT INTO public.beneficiario_participa_ong VALUES ('18900426507', 3, '2019-05-17 00:02:01.650397');
INSERT INTO public.beneficiario_participa_ong VALUES ('37245436669', 3, '2019-05-17 00:02:01.721092');
INSERT INTO public.beneficiario_participa_ong VALUES ('40817856515', 3, '2019-05-17 00:02:01.836709');
INSERT INTO public.beneficiario_participa_ong VALUES ('11463362049', 3, '2019-05-17 00:02:01.940544');
INSERT INTO public.beneficiario_participa_ong VALUES ('42908169240', 3, '2019-05-17 00:02:02.081371');
INSERT INTO public.beneficiario_participa_ong VALUES ('20932011457', 3, '2019-05-17 00:02:02.184986');
INSERT INTO public.beneficiario_participa_ong VALUES ('25566799567', 3, '2019-05-17 00:02:02.282483');
INSERT INTO public.beneficiario_participa_ong VALUES ('28142896319', 3, '2019-05-17 00:02:02.401834');
INSERT INTO public.beneficiario_participa_ong VALUES ('42981337365', 3, '2019-05-17 00:02:02.521154');
INSERT INTO public.beneficiario_participa_ong VALUES ('39868526020', 3, '2019-05-17 00:02:02.638666');
INSERT INTO public.beneficiario_participa_ong VALUES ('24507530690', 3, '2019-05-17 00:02:02.755925');
INSERT INTO public.beneficiario_participa_ong VALUES ('30649836503', 3, '2019-05-17 00:02:02.886451');
INSERT INTO public.beneficiario_participa_ong VALUES ('25591291736', 3, '2019-05-17 00:02:03.018481');
INSERT INTO public.beneficiario_participa_ong VALUES ('37183007160', 3, '2019-05-17 00:02:03.531161');
INSERT INTO public.beneficiario_participa_ong VALUES ('42908169240', 3, '2019-05-17 00:02:03.660444');
INSERT INTO public.beneficiario_participa_ong VALUES ('42981337365', 3, '2019-05-17 00:02:03.781265');
INSERT INTO public.beneficiario_participa_ong VALUES ('44992088462', 3, '2019-05-17 00:02:03.925981');
INSERT INTO public.beneficiario_participa_ong VALUES ('42908169240', 3, '2019-05-17 00:02:04.047069');
INSERT INTO public.beneficiario_participa_ong VALUES ('23735466932', 3, '2019-05-17 00:02:04.18024');
INSERT INTO public.beneficiario_participa_ong VALUES ('30518186547', 1, '2019-05-31 21:06:38.414214');
INSERT INTO public.beneficiario_participa_ong VALUES ('30518186547', 1, '2019-05-31 21:06:42.810752');
INSERT INTO public.beneficiario_participa_ong VALUES ('30518186547', 1, '2019-05-31 21:06:48.401946');
INSERT INTO public.beneficiario_participa_ong VALUES ('30518186547', 1, '2019-05-31 21:07:54.220799');


--
-- Data for Name: beneficiario_possui_responsavel; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.beneficiario_possui_responsavel VALUES ('31401952347', '31401952347');
INSERT INTO public.beneficiario_possui_responsavel VALUES ('21673025963', '21673025963');
INSERT INTO public.beneficiario_possui_responsavel VALUES ('18883017200', '16183960173');
INSERT INTO public.beneficiario_possui_responsavel VALUES ('18883017200', '20526735932');
INSERT INTO public.beneficiario_possui_responsavel VALUES ('48555766757', '20458012821');
INSERT INTO public.beneficiario_possui_responsavel VALUES ('48555766757', '14537734037');
INSERT INTO public.beneficiario_possui_responsavel VALUES ('48555766757', '31939735834');
INSERT INTO public.beneficiario_possui_responsavel VALUES ('48555766757', '48674433818');
INSERT INTO public.beneficiario_possui_responsavel VALUES ('48555766757', '42981337365');
INSERT INTO public.beneficiario_possui_responsavel VALUES ('48555766757', '24507530690');
INSERT INTO public.beneficiario_possui_responsavel VALUES ('48555766757', '40996997281');
INSERT INTO public.beneficiario_possui_responsavel VALUES ('48555766757', '35780054230');
INSERT INTO public.beneficiario_possui_responsavel VALUES ('48555766757', '20932011457');
INSERT INTO public.beneficiario_possui_responsavel VALUES ('48555766757', '28275363183');
INSERT INTO public.beneficiario_possui_responsavel VALUES ('48555766757', '26585095594');
INSERT INTO public.beneficiario_possui_responsavel VALUES ('48555766757', '35258402567');
INSERT INTO public.beneficiario_possui_responsavel VALUES ('48555766757', '11092374501');
INSERT INTO public.beneficiario_possui_responsavel VALUES ('48555766757', '31401952347');
INSERT INTO public.beneficiario_possui_responsavel VALUES ('48555766757', '37245436669');
INSERT INTO public.beneficiario_possui_responsavel VALUES ('48555766757', '46943142992');
INSERT INTO public.beneficiario_possui_responsavel VALUES ('48555766757', '20526735932');
INSERT INTO public.beneficiario_possui_responsavel VALUES ('48555766757', '30649836503');
INSERT INTO public.beneficiario_possui_responsavel VALUES ('48555766757', '23735466932');
INSERT INTO public.beneficiario_possui_responsavel VALUES ('48555766757', '18733143087');


--
-- Data for Name: doacao; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.doacao VALUES ('40996997281', 1, 2, 'Credito', 200, '2019-05-17 00:29:18.063');
INSERT INTO public.doacao VALUES ('25862459414', 2, 3, 'Dinheiro vivo', 0, '2019-05-17 00:29:18.063');
INSERT INTO public.doacao VALUES ('44482700459', 1, 4, 'Debito', 0, '2019-05-17 00:29:18.063');
INSERT INTO public.doacao VALUES ('16183960173', 3, 5, 'Dinheiro vivo', 0, '2019-05-17 00:29:18.063');
INSERT INTO public.doacao VALUES ('47646010006', 4, 6, 'Dinheiro vivo', 0, '2019-05-17 00:29:18.063');
INSERT INTO public.doacao VALUES ('44029404634', 6, 7, 'Credito', 0, '2019-05-17 00:29:18.063');
INSERT INTO public.doacao VALUES ('30518186547', 4, 8, 'Debito', 0, '2019-05-17 00:29:18.063');
INSERT INTO public.doacao VALUES ('24516170603', 1, 9, 'Credito', 0, '2019-05-17 00:29:18.063');
INSERT INTO public.doacao VALUES ('25566799567', 2, 10, 'Debito', 0, '2019-05-17 00:29:18.063');
INSERT INTO public.doacao VALUES ('40718785036', 6, 11, 'Credito', 0, '2019-05-17 00:29:18.063');
INSERT INTO public.doacao VALUES ('33340583598', 4, 12, 'Credito', 0, '2019-05-17 00:29:18.063');
INSERT INTO public.doacao VALUES ('18900426507', 4, 13, 'Debito', 0, '2019-05-17 00:29:18.063');
INSERT INTO public.doacao VALUES ('48555766757', 3, 14, 'Dinheiro vivo', 0, '2019-05-17 00:29:18.063');
INSERT INTO public.doacao VALUES ('19744253222', 9, 15, 'Debito', 0, '2019-05-17 00:29:18.063');
INSERT INTO public.doacao VALUES ('49405306340', 6, 16, 'Debito', 0, '2019-05-17 00:29:18.063');


--
-- Data for Name: log_beneficiario; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.log_beneficiario VALUES (2, '30518186547', 'saida_ong', '2019-05-31 21:05:54.120748');
INSERT INTO public.log_beneficiario VALUES (3, '30518186547', 'saida_ong', '2019-05-31 21:05:54.120748');
INSERT INTO public.log_beneficiario VALUES (4, '30518186547', 'saida_ong', '2019-05-31 21:05:54.120748');
INSERT INTO public.log_beneficiario VALUES (5, '30518186547', 'entrada_ong', '2019-05-31 21:06:38.414214');
INSERT INTO public.log_beneficiario VALUES (6, '30518186547', 'entrada_ong', '2019-05-31 21:06:42.810752');
INSERT INTO public.log_beneficiario VALUES (7, '30518186547', 'entrada_ong', '2019-05-31 21:06:48.401946');
INSERT INTO public.log_beneficiario VALUES (8, '30518186547', 'entrada_ong', '2019-05-31 21:07:54.220799');


--
-- Data for Name: ong; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.ong VALUES ('Ong 1', 1, 'Basil', 'Mitchell', 16968770, 979, '12638008109', 'Tim');
INSERT INTO public.ong VALUES ('Ong 1', 3, 'Basil', 'Mitchell', 16968770, 979, '39981089072', 'Tim');
INSERT INTO public.ong VALUES ('Ong 2', 4, 'Donald', 'Clyde Gallagher', 14765419, 420, '34951806509', 'Tangjiakou');
INSERT INTO public.ong VALUES ('Ong 4', 5, 'Carey', 'Mcguire', 17456197, 352, '18474973323', 'Kon Tum');
INSERT INTO public.ong VALUES ('Ong 5', 6, 'Mcbride', 'Dryden', 16209649, 435, '34277699300', 'Oslo');
INSERT INTO public.ong VALUES ('Ong 6', 7, 'Sullivan', 'Lake View', 10934864, 264, '20458012821', 'Puerto Boyacá');
INSERT INTO public.ong VALUES ('Ong 7', 8, 'Fieldstone', 'Michigan', 14472192, 616, '18883017200', 'Guangyubao');
INSERT INTO public.ong VALUES ('Ong 8', 9, 'Crescent Oaks', 'Cascade', 10337965, 349, '12741896242', 'Zhangshui');
INSERT INTO public.ong VALUES ('Ong 1', 11, 'Basil', 'Mitchell', 16968770, 979, '35258402567', 'Tim');
INSERT INTO public.ong VALUES ('Ong 2', 12, 'Donald', 'Clyde Gallagher', 14765419, 420, '44410183993', 'Tangjiakou');
INSERT INTO public.ong VALUES ('Ong 3', 13, 'Ronald Regan', 'Sycamore', 15314985, 747, '24722672021', 'Non Sila');
INSERT INTO public.ong VALUES ('Ong 4', 14, 'Carey', 'Mcguire', 17456197, 352, '33315351479', 'Kon Tum');
INSERT INTO public.ong VALUES ('Ong 5', 15, 'Mcbride', 'Dryden', 16209649, 435, '25389351858', 'Oslo');
INSERT INTO public.ong VALUES ('Ong 6', 16, 'Sullivan', 'Lake View', 10934864, 264, '24410571935', 'Puerto Boyacá');
INSERT INTO public.ong VALUES ('Ong 7', 17, 'Fieldstone', 'Michigan', 14472192, 616, '33203427206', 'Guangyubao');
INSERT INTO public.ong VALUES ('Ong 1', 20, 'Basil', 'Mitchell', 16968770, 979, '24507530690', 'Tim');
INSERT INTO public.ong VALUES ('Ong 2', 21, 'Donald', 'Clyde Gallagher', 14765419, 420, '21221973017', 'Tangjiakou');
INSERT INTO public.ong VALUES ('Ong 3', 22, 'Ronald Regan', 'Sycamore', 15314985, 747, '35078920437', 'Non Sila');
INSERT INTO public.ong VALUES ('Ong 4', 23, 'Carey', 'Mcguire', 17456197, 352, '36694635187', 'Kon Tum');
INSERT INTO public.ong VALUES ('Ong 5', 24, 'Mcbride', 'Dryden', 16209649, 435, '37183007160', 'Oslo');
INSERT INTO public.ong VALUES ('Ong 1', 26, 'Basil', 'Mitchell', 16968770, 979, '40968535373', 'Tim');
INSERT INTO public.ong VALUES ('Ong 2', 27, 'Donald', 'Clyde Gallagher', 14765419, 420, '45835905239', 'Tangjiakou');
INSERT INTO public.ong VALUES ('Ong 3', 28, 'Ronald Regan', 'Sycamore', 15314985, 747, '41856472055', 'Non Sila');
INSERT INTO public.ong VALUES ('Ong 5', 2, 'Mcbride', 'Dryden', 16209649, 435, '21984776220', 'Oslo');


--
-- Data for Name: pessoa; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.pessoa VALUES ('Bianka Baton', '28202903636', 'Loomis', 725, 'Sycamore', 'Xinxing', 16177022, '2062706465');
INSERT INTO public.pessoa VALUES ('Selestina Briggdale', '26283399289', 'Forest Run', 275, '8th', 'Pancanagara', 17381219, '8488230473');
INSERT INTO public.pessoa VALUES ('Maurits Creus', '46943142992', 'Bay', 972, 'Vidon', 'Cumadcad', 11375097, '6433764854');
INSERT INTO public.pessoa VALUES ('Maud Sharper', '25862459414', 'Walton', 182, 'Ramsey', 'Mantingantengah', 10400022, '5026348845');
INSERT INTO public.pessoa VALUES ('Emmalynn Lemar', '34847001012', 'Florence', 380, 'Oak Valley', 'Chengxi', 16588973, '2714340942');
INSERT INTO public.pessoa VALUES ('Andee Renoden', '39868526020', 'Village', 795, 'Brickson Park', 'Xiaolongmen', 11616245, '1298835780');
INSERT INTO public.pessoa VALUES ('Bethena Sucre', '45797925614', 'Fisk', 254, 'Lakeland', 'Vallenar', 17765284, '7599635262');
INSERT INTO public.pessoa VALUES ('Clotilda Kidds', '49940529791', 'Charing Cross', 204, 'Forest Dale', 'Pyrzyce', 12572911, '5872045061');
INSERT INTO public.pessoa VALUES ('Hale Hymus', '44482700459', 'Tony', 175, 'Dixon', 'Bulung’ur', 18815961, '4559069830');
INSERT INTO public.pessoa VALUES ('Farley Pawellek', '26304019532', 'Tomscot', 798, 'Scoville', 'Lameiro', 16955391, '6753138857');
INSERT INTO public.pessoa VALUES ('Marijo Le Guin', '41235624635', 'Cody', 966, 'Arizona', 'Hlybokaye', 11204037, '6767428061');
INSERT INTO public.pessoa VALUES ('Kenn Christescu', '33266115111', 'Claremont', 150, 'Trailsway', 'Al Bayḑā’', 14428630, '4912908406');
INSERT INTO public.pessoa VALUES ('Bax Dungay', '14537734037', 'Spaight', 40, 'Saint Paul', 'Ibaiti', 11074970, '7044708421');
INSERT INTO public.pessoa VALUES ('Bendix Perrington', '16187655364', 'Carberry', 158, 'Bartelt', 'Kaloyanovo', 14448105, '7535188453');
INSERT INTO public.pessoa VALUES ('Renado Bielfeld', '35078920437', 'Arkansas', 122, 'Sage', 'Da’an', 12973305, '3834680446');
INSERT INTO public.pessoa VALUES ('Milena Bethune', '48755879001', 'Cambridge', 169, 'Blackbird', 'Horred', 15260404, '7764736972');
INSERT INTO public.pessoa VALUES ('Sophi Thurlbeck', '40817856515', 'Dwight', 305, 'Eagle Crest', 'Norrtälje', 10369290, '9256126997');
INSERT INTO public.pessoa VALUES ('Nicol Licciardi', '32124981347', 'Basil', 18, 'Hayes', 'Trélissac', 18538054, '4422913508');
INSERT INTO public.pessoa VALUES ('Ariadne Adney', '23735466932', 'Dovetail', 937, 'Leroy', 'Macaé', 18299838, '4148645455');
INSERT INTO public.pessoa VALUES ('Olympia Achrameev', '27622207747', 'Stuart', 599, 'Mallard', 'Entre Rios', 10955121, '5752106309');
INSERT INTO public.pessoa VALUES ('Naomi Callister', '28142896319', 'Northfield', 822, 'Doe Crossing', 'Passos', 18696744, '1714993023');
INSERT INTO public.pessoa VALUES ('Rosemarie Pettifer', '14152184374', 'Oneill', 623, 'Hooker', 'Mrozy', 12171180, '6411114349');
INSERT INTO public.pessoa VALUES ('Borg Ballaam', '16183960173', 'Lukken', 410, 'Blue Bill Park', 'Taishan', 17455360, '1857321644');
INSERT INTO public.pessoa VALUES ('Isaak Brislan', '31466743141', 'Express', 204, 'Thackeray', 'Al Munīrah', 13199102, '6923955414');
INSERT INTO public.pessoa VALUES ('Martin Sainsbury', '30944416720', 'Helena', 155, 'Namekagon', 'Roanne', 17624261, '6487541443');
INSERT INTO public.pessoa VALUES ('Tam Machon', '43402500898', 'Village', 51, 'Mockingbird', 'Carthage', 14134981, '6232032060');
INSERT INTO public.pessoa VALUES ('Thornie O''Shesnan', '44089506748', 'Esch', 434, 'Fairview', 'Bungabon', 16880894, '6767621670');
INSERT INTO public.pessoa VALUES ('Dimitri Maryan', '35780054230', 'Mallard', 133, 'Elka', 'Jianfeng', 14764930, '4094044612');
INSERT INTO public.pessoa VALUES ('Gunther Blowen', '11270915102', 'Sherman', 19, 'North', 'Digah', 11053569, '1497188406');
INSERT INTO public.pessoa VALUES ('Leonardo Birrell', '16957956090', 'Lakewood Gardens', 179, 'Sunbrook', 'Obolo-Eke (1)', 16275745, '8969028166');
INSERT INTO public.pessoa VALUES ('Kala Dibble', '32365189108', 'Acker', 481, 'Randy', 'Long Xuyên', 17743807, '2015270621');
INSERT INTO public.pessoa VALUES ('Cathlene Flewitt', '27860762969', 'Pawling', 679, 'Red Cloud', 'Tanda', 12417508, '4285633598');
INSERT INTO public.pessoa VALUES ('Theresita Pollington', '47646010006', 'Talisman', 275, 'West', 'Oganlima', 11109356, '8889222297');
INSERT INTO public.pessoa VALUES ('Kris Benadette', '23927762862', 'Moulton', 749, 'Mitchell', 'Benevides', 10506993, '5705342895');
INSERT INTO public.pessoa VALUES ('Shannan Nicholls', '11573348202', 'Lake View', 116, 'Toban', 'Shuitai', 12080540, '6133760921');
INSERT INTO public.pessoa VALUES ('Aeriell Heaker', '40968535373', 'Anzinger', 528, 'Bunting', 'Połaniec', 17104115, '2929102526');
INSERT INTO public.pessoa VALUES ('Armstrong Eskrigg', '39327210257', 'Muir', 465, 'New Castle', 'Quinta dos Frades', 17389286, '2715732204');
INSERT INTO public.pessoa VALUES ('Jarrid Kilday', '28151963866', 'Onsgard', 868, 'Sundown', 'Nomhon', 12003319, '5376994407');
INSERT INTO public.pessoa VALUES ('Renard Pinnere', '10433174837', 'Gerald', 453, 'Karstens', 'Galitsy', 11923327, '3952450116');
INSERT INTO public.pessoa VALUES ('Gelya Baskeyfield', '42908169240', 'Carioca', 798, 'Amoth', 'Chizhou', 18466618, '8543766622');
INSERT INTO public.pessoa VALUES ('Abel Lau', '49169530350', 'Pearson', 125, 'Clove', 'Surulangun Rawas', 11929533, '8967461777');
INSERT INTO public.pessoa VALUES ('Nelson Godilington', '41125765441', 'Kensington', 787, 'Daystar', 'Oued Zem', 11521806, '4065366498');
INSERT INTO public.pessoa VALUES ('Lonee Benini', '19359206243', 'Mifflin', 564, 'Crescent Oaks', 'Arrah', 15089755, '5263591373');
INSERT INTO public.pessoa VALUES ('Neils Drain', '38734672787', 'Dayton', 276, 'Brickson Park', 'Bagombong', 11676375, '4443632267');
INSERT INTO public.pessoa VALUES ('Matthieu Grewcock', '43196002178', 'Merry', 487, 'Vera', 'Al Abyār', 16987800, '5128037473');
INSERT INTO public.pessoa VALUES ('Langsdon Late', '18474973323', 'Kennedy', 717, 'Declaration', 'Hisings Kärra', 13816423, '1394322723');
INSERT INTO public.pessoa VALUES ('Antoni Schirach', '13851731525', 'Ridgeway', 38, 'North', 'Midland', 13930729, '8808274560');
INSERT INTO public.pessoa VALUES ('Britte Batch', '20458012821', 'Mccormick', 123, 'Sage', 'Suruhwadang', 11218765, '4298521909');
INSERT INTO public.pessoa VALUES ('Meyer Canario', '28275363183', 'Anzinger', 227, 'Ilene', 'Anyang', 13079651, '4283990016');
INSERT INTO public.pessoa VALUES ('Noah Pedrielli', '44029404634', 'Jenifer', 722, 'Rigney', 'Campo Largo', 12652986, '8895131653');
INSERT INTO public.pessoa VALUES ('Lori Deppe', '38822912761', 'Granby', 767, 'Declaration', 'Shangjing', 15284686, '6817182422');
INSERT INTO public.pessoa VALUES ('Fayth Ferguson', '37590368496', 'Rieder', 942, 'Farmco', 'Ad Dīs ash Sharqīyah', 12700974, '2576984146');
INSERT INTO public.pessoa VALUES ('Baxie Coal', '39925771438', 'Coolidge', 784, 'Stone Corner', 'Tríkala', 15688317, '9348547356');
INSERT INTO public.pessoa VALUES ('Renault Coggins', '23795372198', 'Summit', 396, 'Roxbury', 'Quintães', 14215818, '8282728513');
INSERT INTO public.pessoa VALUES ('Viviyan Haskew', '14933292248', 'Scofield', 379, 'Dixon', 'Maroua', 10253040, '9665904209');
INSERT INTO public.pessoa VALUES ('Farlie Freke', '11092374501', 'Messerschmidt', 272, 'Emmet', 'Santa Rosa de Aguán', 13988367, '3471965131');
INSERT INTO public.pessoa VALUES ('Jewel Skinley', '30518186547', 'Golden Leaf', 606, 'Burrows', 'Yaxi', 15922718, '3922602779');
INSERT INTO public.pessoa VALUES ('Aldon Henrionot', '37245436669', 'Del Sol', 333, 'Rusk', 'Dushu', 10960385, '2454822328');
INSERT INTO public.pessoa VALUES ('Rianon Begwell', '33203427206', 'Esch', 964, 'Center', 'Ragay', 17577709, '4029351401');
INSERT INTO public.pessoa VALUES ('Windy Byrth', '11947399515', 'Rowland', 269, 'Fallview', 'Cieurih Satu', 17384393, '1664603813');
INSERT INTO public.pessoa VALUES ('Roby Archer', '42981337365', 'Eastlawn', 147, 'Loomis', 'Olesno', 15889930, '3098452392');
INSERT INTO public.pessoa VALUES ('Cindee Dragoe', '11319778326', 'Jackson', 674, 'Old Shore', 'Gombangan', 17048218, '2015711748');
INSERT INTO public.pessoa VALUES ('Pippa Heales', '44992088462', 'Golden Leaf', 965, 'Brentwood', 'Duwe', 11011565, '3473312266');
INSERT INTO public.pessoa VALUES ('Godiva Dillaway', '30218927780', 'Lyons', 89, 'Memorial', 'Gibara', 17404917, '4213904554');
INSERT INTO public.pessoa VALUES ('Ryun Aronstein', '42430907330', 'Pond', 464, 'Sunbrook', 'Veshnyaki', 17177522, '8421269554');
INSERT INTO public.pessoa VALUES ('Ilyse O''Sheils', '26971137510', 'John Wall', 585, 'Cherokee', 'Suraż', 14678522, '2294871560');
INSERT INTO public.pessoa VALUES ('Chere Kroin', '34277699300', 'Briar Crest', 764, 'Cardinal', 'Mengdong', 17413045, '7476554508');
INSERT INTO public.pessoa VALUES ('Athene Winks', '49390794264', 'Dorton', 255, 'Transport', 'Imbang', 10732460, '1692232679');
INSERT INTO public.pessoa VALUES ('Sheri Vasichev', '19934703478', 'Messerschmidt', 105, 'Bowman', 'Kamba', 17140366, '3395791298');
INSERT INTO public.pessoa VALUES ('Opaline Martinetto', '20770590202', 'Katie', 160, 'Bashford', 'Horní Suchá', 15984936, '1126538330');
INSERT INTO public.pessoa VALUES ('Faustina Bartolomeu', '14345851603', 'Jenifer', 94, 'Independence', 'Thanh Khê', 15413563, '7001800476');
INSERT INTO public.pessoa VALUES ('Broddie Triggol', '24516170603', 'Northridge', 862, 'Fair Oaks', 'Yushan', 17282404, '8942492267');
INSERT INTO public.pessoa VALUES ('Dew Wolstencroft', '47893175447', 'Tennessee', 144, 'Oak', 'Kribi', 12515590, '1513891098');
INSERT INTO public.pessoa VALUES ('Bette Harms', '13250297171', 'Marcy', 275, 'Derek', 'Bluefields', 15988949, '6337529695');
INSERT INTO public.pessoa VALUES ('Fey Battrick', '12638008109', 'Elmside', 944, 'Fisk', 'Ibarreta', 15483376, '8701083373');
INSERT INTO public.pessoa VALUES ('Willey Iglesias', '20932011457', 'Glendale', 15, 'Rockefeller', 'Zhulin', 10258685, '1103886319');
INSERT INTO public.pessoa VALUES ('Lynnea McGinney', '41587862440', 'Fordem', 342, 'Coleman', 'Aracaju', 15524093, '8207472385');
INSERT INTO public.pessoa VALUES ('Emilee Chippendale', '29289391195', 'Burning Wood', 49, 'Fairfield', 'Nanping', 18428709, '4585811034');
INSERT INTO public.pessoa VALUES ('Brina Sier', '40746485547', 'Farwell', 579, 'Sutherland', 'Fajã de Cima', 18872163, '8564893363');
INSERT INTO public.pessoa VALUES ('Lilias Espada', '25566799567', 'Mitchell', 939, 'Roth', 'Ramón Castilla', 13175335, '5907626287');
INSERT INTO public.pessoa VALUES ('Barbara Sueter', '18372614361', 'Buhler', 3, 'Sheridan', 'Pingtan', 15136394, '1559795185');
INSERT INTO public.pessoa VALUES ('Alwyn Zambon', '36643294146', 'Buhler', 302, 'Oak', 'Göteborg', 11717459, '3515452229');
INSERT INTO public.pessoa VALUES ('Blakeley De Benedetti', '39061602335', 'Brickson Park', 425, 'Magdeline', 'Mtwango', 15721196, '3064428723');
INSERT INTO public.pessoa VALUES ('Leonore Dallan', '15900706685', 'Fallview', 342, 'Florence', 'Vynohradivka', 12939231, '1862185254');
INSERT INTO public.pessoa VALUES ('Corbet Grellis', '48674433818', 'Onsgard', 187, 'Ilene', 'Neob', 15017669, '3112948540');
INSERT INTO public.pessoa VALUES ('Reidar Do Rosario', '39526817270', 'Reindahl', 742, 'Moulton', 'Calarcá', 14992168, '3121464185');
INSERT INTO public.pessoa VALUES ('Lovell Yter', '31132589299', 'Doe Crossing', 398, 'Texas', 'Talisayan', 11675095, '7045246726');
INSERT INTO public.pessoa VALUES ('Kassie Saker', '47785381852', '6th', 923, 'Canary', 'Kari', 14671258, '3349930529');
INSERT INTO public.pessoa VALUES ('Jessalyn Rainon', '44020757035', 'Acker', 981, 'Bartelt', 'Wufeng', 15112197, '7633768515');
INSERT INTO public.pessoa VALUES ('Franny Balaam', '12987095821', 'Summit', 914, 'Buell', 'Yangzhuang', 11030023, '8758492760');
INSERT INTO public.pessoa VALUES ('Gaby Hyam', '40718785036', 'Hudson', 984, 'Spaight', 'Puerto Boyacá', 16489875, '9471029681');
INSERT INTO public.pessoa VALUES ('Olimpia Coenraets', '44775485403', 'Cody', 17, 'Prairie Rose', 'Krajan Siki', 12049197, '9458656223');
INSERT INTO public.pessoa VALUES ('Natalina Valeri', '21984776220', 'Walton', 856, 'Michigan', 'Changuillo', 17409555, '6501082023');
INSERT INTO public.pessoa VALUES ('Tasha Budgeon', '21985859642', 'Spaight', 234, 'Eagle Crest', 'Fizuli', 14154685, '2132383157');
INSERT INTO public.pessoa VALUES ('Madalyn Mushawe', '24507530690', 'Lukken', 715, 'Pierstorff', 'Hartola', 13504115, '1801311785');
INSERT INTO public.pessoa VALUES ('Luce Lutty', '15808041190', 'Lunder', 987, 'Ryan', 'Ulsan', 10588331, '8876782273');
INSERT INTO public.pessoa VALUES ('Filberte Giraldez', '12212916192', 'American', 917, 'Novick', 'Kalchevaya', 18910045, '8624510082');
INSERT INTO public.pessoa VALUES ('Sandi Truse', '23620158237', 'Old Shore', 809, 'Reinke', 'Gostyń', 10296985, '6032462732');
INSERT INTO public.pessoa VALUES ('Leroi Barkly', '35258402567', '5th', 726, 'Canary', 'Pragen Selatan', 14972067, '9193738416');
INSERT INTO public.pessoa VALUES ('Livvyy Cathel', '26686277983', 'Miller', 652, 'Ilene', 'Kyenjojo', 18787288, '9282103896');
INSERT INTO public.pessoa VALUES ('Martha Amies', '11957387601', 'Bunker Hill', 412, 'Anthes', 'Balgatay', 16658476, '6411410702');
INSERT INTO public.pessoa VALUES ('Freddi Lyptrit', '26585095594', 'South', 779, 'Norway Maple', 'Telbang', 13871365, '5242160799');
INSERT INTO public.pessoa VALUES ('Leonie McCrory', '10663247031', 'Dennis', 138, 'Macpherson', 'Panbang', 16812188, '9214392137');
INSERT INTO public.pessoa VALUES ('Zelig Poter', '20526735932', 'Toban', 416, 'Springs', 'Skellefteå', 14717732, '2648310367');
INSERT INTO public.pessoa VALUES ('Darbie Lathleiffure', '33340583598', 'Holy Cross', 139, 'Esch', 'Gaoyi', 16555107, '1402805017');
INSERT INTO public.pessoa VALUES ('Sig Halfacre', '30666915416', 'Spenser', 785, 'Arapahoe', 'Alcabideche', 18315172, '3627961510');
INSERT INTO public.pessoa VALUES ('Cissiee Branthwaite', '48317440622', 'Novick', 565, 'Bowman', 'Xinan', 18432731, '6871646804');
INSERT INTO public.pessoa VALUES ('Horten Yaxley', '46879518614', 'Dryden', 408, 'Veith', 'Ḩajjah', 13731538, '4332234878');
INSERT INTO public.pessoa VALUES ('Hurlee Amori', '29058930464', 'Stang', 498, 'Forster', 'Camgyai', 14176622, '8963265136');
INSERT INTO public.pessoa VALUES ('Angelle Malloch', '36567329970', 'Northport', 30, 'Rigney', 'Roriz', 11404603, '7072367422');
INSERT INTO public.pessoa VALUES ('Hyacintha Duffrie', '25499973443', 'Mifflin', 603, 'Montana', 'Cruzeiro', 12833093, '1881447773');
INSERT INTO public.pessoa VALUES ('Linnet Brumham', '36812224687', 'Warrior', 938, 'Montana', 'Krapina', 12879118, '1215600980');
INSERT INTO public.pessoa VALUES ('Mariellen Yakobovicz', '21673025963', 'Eastlawn', 351, 'Rieder', 'Bolszewo', 13161202, '2575622834');
INSERT INTO public.pessoa VALUES ('Zorah Guesford', '12741896242', 'Westport', 950, 'Riverside', 'Shiwan', 14466741, '8344947474');
INSERT INTO public.pessoa VALUES ('Carson Abbie', '18147535796', 'Monument', 551, 'Prairie Rose', 'Columbeira', 17118373, '1297089396');
INSERT INTO public.pessoa VALUES ('Lesli Cassar', '13694028753', 'Kropf', 91, 'Sloan', 'Qazax', 15804885, '2601512081');
INSERT INTO public.pessoa VALUES ('Donella Hold', '10292218291', 'Di Loreto', 924, 'Blaine', 'Hainan', 14790917, '3083789466');
INSERT INTO public.pessoa VALUES ('Odilia McAleese', '18326411781', 'Lighthouse Bay', 320, 'Hovde', 'Ukhta', 18831889, '7459097257');
INSERT INTO public.pessoa VALUES ('Claybourne Blackbrough', '36694635187', 'Miller', 646, 'Oakridge', 'Tartu', 11686240, '8574616453');
INSERT INTO public.pessoa VALUES ('Jonas Tanti', '17351242993', 'Karstens', 773, 'Eagle Crest', 'Nartkala', 18855411, '9948426128');
INSERT INTO public.pessoa VALUES ('Brooks Feaveryear', '18900426507', 'Lukken', 912, 'Sycamore', 'Baoshan', 11798275, '4387560745');
INSERT INTO public.pessoa VALUES ('Raquela Maylor', '30835460101', 'Sullivan', 831, 'Weeping Birch', 'Ponikiew', 11031293, '1062802722');
INSERT INTO public.pessoa VALUES ('Chilton Orme', '10636339202', 'Harbort', 234, 'Anderson', 'Khawrah', 11927267, '9233578634');
INSERT INTO public.pessoa VALUES ('Germaine Loseke', '41856472055', 'Logan', 923, 'Bluestem', 'Zaniemyśl', 16003727, '9892582443');
INSERT INTO public.pessoa VALUES ('Marcelle Tym', '21247567781', 'Dunning', 260, 'Becker', 'Sui’an', 18763351, '6166095859');
INSERT INTO public.pessoa VALUES ('Kaela Chessil', '16464979798', 'Walton', 929, 'Dakota', 'San Francisco', 18264438, '7972199737');
INSERT INTO public.pessoa VALUES ('Meyer Aish', '16930863208', 'Swallow', 908, 'Brown', 'Souto da Casa', 15998050, '4454159198');
INSERT INTO public.pessoa VALUES ('Annecorinne Saines', '11597795854', 'Northview', 857, 'Oxford', 'Barra dos Coqueiros', 12247332, '3146880101');
INSERT INTO public.pessoa VALUES ('Carleen Biddles', '39256701522', 'Hovde', 536, 'International', 'Dimayon', 10977228, '6316446466');
INSERT INTO public.pessoa VALUES ('Wylma Ekkel', '40836552506', 'Arkansas', 449, 'Prairieview', 'Seseng', 13025598, '9887691110');
INSERT INTO public.pessoa VALUES ('Wenonah Haine', '40996997281', 'Darwin', 918, 'Birchwood', 'Tulle', 16569263, '9199664634');
INSERT INTO public.pessoa VALUES ('Marjorie Hanstock', '17416229636', 'Crest Line', 2, 'Orin', 'Isla Verde', 12984530, '2121426664');
INSERT INTO public.pessoa VALUES ('Corbie Cappell', '18883017200', 'Heffernan', 486, 'Oak', 'Mosteirô', 17509926, '3147463347');
INSERT INTO public.pessoa VALUES ('Gun Plaster', '19315290560', 'Fulton', 532, 'International', 'Lycksele', 13948461, '3661013084');
INSERT INTO public.pessoa VALUES ('Shepherd Denney', '31940407254', 'Pepper Wood', 919, 'Homewood', 'Meilin', 15494298, '6474410017');
INSERT INTO public.pessoa VALUES ('Godwin Chantree', '24410571935', 'Eastwood', 392, 'Nova', 'Calabugao', 13106777, '1909157782');
INSERT INTO public.pessoa VALUES ('Frankie Suller', '38886347430', 'Mayer', 764, 'Gateway', 'Akita', 14359913, '7996255308');
INSERT INTO public.pessoa VALUES ('Georgy Spong', '48555766757', '1st', 100, 'Kingsford', 'Derzhavīnsk', 11071288, '2213216677');
INSERT INTO public.pessoa VALUES ('Tildie Baglin', '42875993149', 'Mcbride', 272, 'Macpherson', 'Wonorejo', 10451667, '9303433096');
INSERT INTO public.pessoa VALUES ('Adrea Nairn', '12571327622', 'Butterfield', 851, 'Hanover', 'Pampamarca', 13596688, '6213276115');
INSERT INTO public.pessoa VALUES ('Lacee Drillingcourt', '12380522076', 'Redwing', 590, 'Gateway', 'Vilarinho da Castanheira', 10853117, '1635786926');
INSERT INTO public.pessoa VALUES ('Helenka Sweetland', '33488249723', 'Little Fleur', 216, '7th', 'Kolbano', 10742643, '3957515974');
INSERT INTO public.pessoa VALUES ('Gill Matzaitis', '35501049185', 'Monterey', 240, 'Village', 'Ptení', 12520142, '5424440321');
INSERT INTO public.pessoa VALUES ('West Kidwell', '19930504867', 'Vahlen', 263, 'Westerfield', 'Tengah', 16429607, '4451630822');
INSERT INTO public.pessoa VALUES ('Bondon Bramhall', '31939735834', 'Thompson', 75, 'Chinook', 'Wiązownica', 15013322, '1677022538');
INSERT INTO public.pessoa VALUES ('Morganica Linzee', '48650595784', 'Harbort', 210, 'Meadow Vale', 'Ozerne', 13848414, '1057063270');
INSERT INTO public.pessoa VALUES ('Fifi Gidman', '37183007160', 'Sullivan', 729, 'Northview', 'Pingya', 16847503, '4703013920');
INSERT INTO public.pessoa VALUES ('Elane Bembrigg', '45835905239', 'Longview', 686, 'Warner', 'Osvaldo Cruz', 12440972, '9619386538');
INSERT INTO public.pessoa VALUES ('Bryon Gibbonson', '25389351858', 'Corry', 731, 'Mallard', 'Armstrong', 17590853, '9045695089');
INSERT INTO public.pessoa VALUES ('Jakie Gavey', '35500855091', 'Brown', 917, 'Dorton', 'Bujanovac', 15167517, '2496053017');
INSERT INTO public.pessoa VALUES ('Nanete Chree', '12230306633', 'Goodland', 680, 'Lake View', 'Limoges', 16047522, '1665300508');
INSERT INTO public.pessoa VALUES ('Agace Fane', '19744253222', 'Carioca', 244, 'Main', 'Daguyun', 18968620, '8014885325');
INSERT INTO public.pessoa VALUES ('Jerri Jeyness', '10099157165', 'Veith', 236, 'Cordelia', 'Bunog', 11079223, '7976872721');
INSERT INTO public.pessoa VALUES ('Averell Bredbury', '28505561938', 'Prentice', 107, 'Hudson', 'Brodek u Přerova', 10765311, '4589705765');
INSERT INTO public.pessoa VALUES ('Abram Nelligan', '22664675417', 'Jenifer', 572, 'Jenna', 'Monte da Boavista', 15372043, '3763977968');
INSERT INTO public.pessoa VALUES ('Merv Fogg', '32033625198', 'Jackson', 570, 'Melby', 'Heting', 13251796, '3885166822');
INSERT INTO public.pessoa VALUES ('Gallard Aasaf', '32112462243', 'Golf', 110, 'Sheridan', 'Fu’an', 10190264, '8008869168');
INSERT INTO public.pessoa VALUES ('Christi Olivella', '25565616079', 'Dahle', 904, 'Dottie', 'Guadalupe', 17020616, '2095433930');
INSERT INTO public.pessoa VALUES ('Ignace Eicheler', '30173287601', 'Birchwood', 363, 'Bobwhite', 'Lhari', 18425151, '2675163916');
INSERT INTO public.pessoa VALUES ('Jervis Vanlint', '44235351721', 'Coleman', 551, 'Reindahl', 'Chaiyaphum', 12207320, '3015782947');
INSERT INTO public.pessoa VALUES ('Oliver MacKall', '33315351479', 'Nelson', 900, 'Meadow Vale', 'Gayny', 13577235, '9362810239');
INSERT INTO public.pessoa VALUES ('Marcellina Zarb', '30649836503', 'Mallory', 855, 'La Follette', 'Belogorsk', 18849447, '2964158789');
INSERT INTO public.pessoa VALUES ('Jermain Teck', '43706938642', 'Stoughton', 867, 'Dahle', 'Haoba', 17486003, '7608694599');
INSERT INTO public.pessoa VALUES ('Orv Valens-Smith', '23166519965', 'Maple Wood', 27, 'La Follette', 'Qinling Jieban', 11226353, '2448934600');
INSERT INTO public.pessoa VALUES ('Corine Slocum', '12084180181', 'Hazelcrest', 296, 'Arrowood', 'Linstead', 10535715, '3347763246');
INSERT INTO public.pessoa VALUES ('Tedman Mattisssen', '37259632003', 'Charing Cross', 61, 'Veith', 'Lameiras', 15628362, '7614419210');
INSERT INTO public.pessoa VALUES ('Rose Consadine', '11463362049', 'Harbort', 992, 'Del Sol', 'Marne-la-Vallée', 18124800, '2439258648');
INSERT INTO public.pessoa VALUES ('Elia Geockle', '23149134498', 'Stone Corner', 126, 'Forest', 'Lebowakgomo', 16845700, '9984403889');
INSERT INTO public.pessoa VALUES ('Malchy Morfey', '22042363636', 'Wayridge', 97, 'Southridge', 'Lebedinovka', 18073630, '1101187400');
INSERT INTO public.pessoa VALUES ('Nicholas Whitty', '41696931198', 'Rieder', 795, 'Roxbury', 'Saint-Raymond', 11260110, '1256548355');
INSERT INTO public.pessoa VALUES ('Missie Gavrieli', '24722672021', 'Fair Oaks', 761, 'Mcguire', 'Wanfang', 12650335, '5071816999');
INSERT INTO public.pessoa VALUES ('Clemmie Christophersen', '19272772696', 'Manley', 912, 'Crownhardt', 'Ristinummi', 10354362, '8205038657');
INSERT INTO public.pessoa VALUES ('Savina Riveles', '33259510731', 'Autumn Leaf', 543, 'Schmedeman', 'Pégeia', 14540330, '1127364068');
INSERT INTO public.pessoa VALUES ('Donny Meadowcraft', '49405306340', 'High Crossing', 426, 'Sheridan', 'Timrå', 13960376, '4556376182');
INSERT INTO public.pessoa VALUES ('Araldo Gingel', '34951806509', 'Service', 575, 'Sycamore', 'Tashi', 11346240, '4636109972');
INSERT INTO public.pessoa VALUES ('Gilberta Stocken', '44410183993', 'Michigan', 303, 'Namekagon', 'Nambak Tengah', 10755145, '9534821529');
INSERT INTO public.pessoa VALUES ('Maure Josefowicz', '15818472874', 'Calypso', 121, 'Jenna', 'Ta Khmau', 14065361, '1028729778');
INSERT INTO public.pessoa VALUES ('Monique Gabbott', '36483837924', 'Green', 382, 'Northland', 'Okahandja', 15218196, '5062926642');
INSERT INTO public.pessoa VALUES ('Balduin Ewbank', '25554925252', 'Schiller', 761, 'Tomscot', 'Kodyma', 10213164, '7007354942');
INSERT INTO public.pessoa VALUES ('Jade Donati', '25151533522', 'Dennis', 613, 'Mallard', 'Dmitrov', 14829456, '9942247076');
INSERT INTO public.pessoa VALUES ('Cherie Witherbed', '38434891046', 'Aberg', 927, 'Harbort', 'Ḑawrān ad Daydah', 18288195, '9505252011');
INSERT INTO public.pessoa VALUES ('Marcello Beardmore', '28542574558', 'Iowa', 385, 'Vahlen', 'Carahue', 15801910, '5575843492');
INSERT INTO public.pessoa VALUES ('Laurene Raith', '11309870858', 'Golden Leaf', 744, 'Macpherson', 'Divnomorskoye', 16819888, '8505285491');
INSERT INTO public.pessoa VALUES ('Denver Vasyutochkin', '39981089072', '4th', 184, 'Dexter', 'Sabang', 18974403, '1223836282');
INSERT INTO public.pessoa VALUES ('Modestia Gateshill', '46213748754', 'Hanson', 922, 'Summer Ridge', 'Quezaltepeque', 15785232, '2491297765');
INSERT INTO public.pessoa VALUES ('Rossie Adney', '25591291736', 'Maple', 707, 'Anniversary', 'Sancha', 15918374, '9364575565');
INSERT INTO public.pessoa VALUES ('Bobette Smeaton', '41534663517', 'Spohn', 531, 'American', 'Aiánteio', 15052719, '5841524308');
INSERT INTO public.pessoa VALUES ('Hobey Gawith', '18733143087', 'Autumn Leaf', 569, 'Orin', 'Aparecida do Taboado', 16774496, '8138658874');
INSERT INTO public.pessoa VALUES ('Conny Pryer', '46499914772', 'Cascade', 630, 'Pine View', 'Wanshi', 14897668, '7874562534');
INSERT INTO public.pessoa VALUES ('Rhody Hiley', '24346513086', 'David', 190, 'Sunbrook', 'Taclobo', 15283197, '4666093503');
INSERT INTO public.pessoa VALUES ('Zorah Spikins', '27329124880', 'Bunker Hill', 439, 'Mandrake', 'Buqei‘a', 12975158, '9317536705');
INSERT INTO public.pessoa VALUES ('Tybalt Lockart', '21221973017', 'Shasta', 186, 'Talisman', 'San Clemente', 16520906, '7165196124');
INSERT INTO public.pessoa VALUES ('Adoree Martusewicz', '13642279807', 'Warner', 15, 'Mockingbird', 'Vihāri', 14087698, '2792334935');
INSERT INTO public.pessoa VALUES ('Sherwood Grigorian', '40181557129', 'East', 587, 'Del Mar', 'Franceville', 14606698, '6002346924');
INSERT INTO public.pessoa VALUES ('Essa Oran', '31401952347', 'Burrows', 515, 'Kipling', 'Grand Forks', 12384202, '7015638647');
INSERT INTO public.pessoa VALUES ('Flem Rapp', '49721368011', 'Westridge', 284, 'Hoard', 'Borzęcin', 11410206, '6383644074');
INSERT INTO public.pessoa VALUES ('Kylie Meneux', '43103050722', 'American', 842, 'Novick', 'Além', 16553587, '4461258094');
INSERT INTO public.pessoa VALUES ('Chevalier Aykroyd', '39470440513', 'Meadow Ridge', 947, 'Calypso', 'Vypolzovo', 18943530, '6979150389');
INSERT INTO public.pessoa VALUES ('Clair Langwade', '38793272370', 'Pearson', 21, 'Sundown', 'Wangjiaping', 16036135, '7357218229');
INSERT INTO public.pessoa VALUES ('Matthieu Wholesworth', '22816126925', 'Bultman', 673, 'Hagan', 'Pigcawayan', 15259069, '4459567015');


--
-- Data for Name: voluntario; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.voluntario VALUES ('12638008109');
INSERT INTO public.voluntario VALUES ('39925771438');
INSERT INTO public.voluntario VALUES ('18883017200');
INSERT INTO public.voluntario VALUES ('38734672787');
INSERT INTO public.voluntario VALUES ('12230306633');
INSERT INTO public.voluntario VALUES ('39981089072');
INSERT INTO public.voluntario VALUES ('18900426507');
INSERT INTO public.voluntario VALUES ('36694635187');
INSERT INTO public.voluntario VALUES ('45835905239');
INSERT INTO public.voluntario VALUES ('21984776220');
INSERT INTO public.voluntario VALUES ('20932011457');
INSERT INTO public.voluntario VALUES ('18147535796');
INSERT INTO public.voluntario VALUES ('33203427206');
INSERT INTO public.voluntario VALUES ('20458012821');
INSERT INTO public.voluntario VALUES ('37183007160');
INSERT INTO public.voluntario VALUES ('19315290560');
INSERT INTO public.voluntario VALUES ('41534663517');
INSERT INTO public.voluntario VALUES ('17351242993');
INSERT INTO public.voluntario VALUES ('47893175447');
INSERT INTO public.voluntario VALUES ('48674433818');
INSERT INTO public.voluntario VALUES ('24410571935');
INSERT INTO public.voluntario VALUES ('20526735932');
INSERT INTO public.voluntario VALUES ('40817856515');
INSERT INTO public.voluntario VALUES ('12571327622');
INSERT INTO public.voluntario VALUES ('34951806509');
INSERT INTO public.voluntario VALUES ('11319778326');
INSERT INTO public.voluntario VALUES ('15808041190');
INSERT INTO public.voluntario VALUES ('21221973017');
INSERT INTO public.voluntario VALUES ('25389351858');
INSERT INTO public.voluntario VALUES ('41856472055');
INSERT INTO public.voluntario VALUES ('25554925252');
INSERT INTO public.voluntario VALUES ('35258402567');
INSERT INTO public.voluntario VALUES ('46879518614');
INSERT INTO public.voluntario VALUES ('26686277983');
INSERT INTO public.voluntario VALUES ('33315351479');
INSERT INTO public.voluntario VALUES ('13851731525');
INSERT INTO public.voluntario VALUES ('36567329970');
INSERT INTO public.voluntario VALUES ('40968535373');
INSERT INTO public.voluntario VALUES ('22042363636');
INSERT INTO public.voluntario VALUES ('15900706685');
INSERT INTO public.voluntario VALUES ('26585095594');
INSERT INTO public.voluntario VALUES ('44410183993');
INSERT INTO public.voluntario VALUES ('24507530690');
INSERT INTO public.voluntario VALUES ('23149134498');
INSERT INTO public.voluntario VALUES ('27860762969');
INSERT INTO public.voluntario VALUES ('14345851603');
INSERT INTO public.voluntario VALUES ('38886347430');
INSERT INTO public.voluntario VALUES ('24722672021');
INSERT INTO public.voluntario VALUES ('18474973323');
INSERT INTO public.voluntario VALUES ('39470440513');
INSERT INTO public.voluntario VALUES ('34277699300');
INSERT INTO public.voluntario VALUES ('39327210257');
INSERT INTO public.voluntario VALUES ('35078920437');
INSERT INTO public.voluntario VALUES ('36812224687');
INSERT INTO public.voluntario VALUES ('12741896242');
INSERT INTO public.voluntario VALUES ('49390794264');


--
-- Data for Name: voluntario_voluntaria_ong; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.voluntario_voluntaria_ong VALUES ('33315351479', 2, '2019-05-17 00:25:31.08341');
INSERT INTO public.voluntario_voluntaria_ong VALUES ('13851731525', 2, '2019-05-17 00:25:31.08341');
INSERT INTO public.voluntario_voluntaria_ong VALUES ('21221973017', 2, '2019-05-17 00:25:31.178884');
INSERT INTO public.voluntario_voluntaria_ong VALUES ('25389351858', 2, '2019-05-17 00:25:31.178884');
INSERT INTO public.voluntario_voluntaria_ong VALUES ('14345851603', 2, '2019-05-17 00:25:31.33709');
INSERT INTO public.voluntario_voluntaria_ong VALUES ('38886347430', 2, '2019-05-17 00:25:31.33709');
INSERT INTO public.voluntario_voluntaria_ong VALUES ('17351242993', 2, '2019-05-17 00:25:31.559886');
INSERT INTO public.voluntario_voluntaria_ong VALUES ('47893175447', 2, '2019-05-17 00:25:31.559886');
INSERT INTO public.voluntario_voluntaria_ong VALUES ('21984776220', 2, '2019-05-17 00:25:31.856168');
INSERT INTO public.voluntario_voluntaria_ong VALUES ('20932011457', 2, '2019-05-17 00:25:31.856168');
INSERT INTO public.voluntario_voluntaria_ong VALUES ('18147535796', 2, '2019-05-17 00:25:31.969759');
INSERT INTO public.voluntario_voluntaria_ong VALUES ('33203427206', 2, '2019-05-17 00:25:31.969759');
INSERT INTO public.voluntario_voluntaria_ong VALUES ('23149134498', 2, '2019-05-17 00:25:32.191514');
INSERT INTO public.voluntario_voluntaria_ong VALUES ('27860762969', 2, '2019-05-17 00:25:32.191514');
INSERT INTO public.voluntario_voluntaria_ong VALUES ('39981089072', 2, '2019-05-17 00:25:32.418451');
INSERT INTO public.voluntario_voluntaria_ong VALUES ('18900426507', 2, '2019-05-17 00:25:32.418451');
INSERT INTO public.voluntario_voluntaria_ong VALUES ('36694635187', 2, '2019-05-17 00:25:32.521681');
INSERT INTO public.voluntario_voluntaria_ong VALUES ('45835905239', 2, '2019-05-17 00:25:32.521681');
INSERT INTO public.voluntario_voluntaria_ong VALUES ('44410183993', 2, '2019-05-17 00:25:32.663041');
INSERT INTO public.voluntario_voluntaria_ong VALUES ('24507530690', 2, '2019-05-17 00:25:32.663041');
INSERT INTO public.voluntario_voluntaria_ong VALUES ('41856472055', 2, '2019-05-17 00:25:32.866185');
INSERT INTO public.voluntario_voluntaria_ong VALUES ('25554925252', 2, '2019-05-17 00:25:32.866185');
INSERT INTO public.voluntario_voluntaria_ong VALUES ('36812224687', 1, '2019-05-17 00:25:37.117203');
INSERT INTO public.voluntario_voluntaria_ong VALUES ('12741896242', 1, '2019-05-17 00:25:37.117203');
INSERT INTO public.voluntario_voluntaria_ong VALUES ('33203427206', 1, '2019-05-17 00:25:37.185277');
INSERT INTO public.voluntario_voluntaria_ong VALUES ('20458012821', 1, '2019-05-17 00:25:37.185277');
INSERT INTO public.voluntario_voluntaria_ong VALUES ('18900426507', 1, '2019-05-17 00:25:37.293713');
INSERT INTO public.voluntario_voluntaria_ong VALUES ('36694635187', 1, '2019-05-17 00:25:37.293713');
INSERT INTO public.voluntario_voluntaria_ong VALUES ('24722672021', 1, '2019-05-17 00:25:37.41539');
INSERT INTO public.voluntario_voluntaria_ong VALUES ('18474973323', 1, '2019-05-17 00:25:37.41539');
INSERT INTO public.voluntario_voluntaria_ong VALUES ('13851731525', 1, '2019-05-17 00:25:37.509041');
INSERT INTO public.voluntario_voluntaria_ong VALUES ('36567329970', 1, '2019-05-17 00:25:37.509041');
INSERT INTO public.voluntario_voluntaria_ong VALUES ('18883017200', 1, '2019-05-17 00:25:37.962308');
INSERT INTO public.voluntario_voluntaria_ong VALUES ('38734672787', 1, '2019-05-17 00:25:37.962308');
INSERT INTO public.voluntario_voluntaria_ong VALUES ('41534663517', 1, '2019-05-17 00:25:38.177137');
INSERT INTO public.voluntario_voluntaria_ong VALUES ('17351242993', 1, '2019-05-17 00:25:38.177137');
INSERT INTO public.voluntario_voluntaria_ong VALUES ('25389351858', 1, '2019-05-17 00:25:38.306832');
INSERT INTO public.voluntario_voluntaria_ong VALUES ('41856472055', 1, '2019-05-17 00:25:38.306832');
INSERT INTO public.voluntario_voluntaria_ong VALUES ('48674433818', 1, '2019-05-17 00:25:38.405941');
INSERT INTO public.voluntario_voluntaria_ong VALUES ('24410571935', 1, '2019-05-17 00:25:38.405941');
INSERT INTO public.voluntario_voluntaria_ong VALUES ('34277699300', 1, '2019-05-17 00:25:38.520285');
INSERT INTO public.voluntario_voluntaria_ong VALUES ('39327210257', 1, '2019-05-17 00:25:38.520285');
INSERT INTO public.voluntario_voluntaria_ong VALUES ('45835905239', 1, '2019-05-17 00:25:38.863722');
INSERT INTO public.voluntario_voluntaria_ong VALUES ('21984776220', 1, '2019-05-17 00:25:38.863722');
INSERT INTO public.voluntario_voluntaria_ong VALUES ('15900706685', 3, '2019-05-17 00:25:43.626626');
INSERT INTO public.voluntario_voluntaria_ong VALUES ('26585095594', 3, '2019-05-17 00:25:43.626626');
INSERT INTO public.voluntario_voluntaria_ong VALUES ('17351242993', 3, '2019-05-17 00:25:43.743037');
INSERT INTO public.voluntario_voluntaria_ong VALUES ('47893175447', 3, '2019-05-17 00:25:43.743037');
INSERT INTO public.voluntario_voluntaria_ong VALUES ('11319778326', 3, '2019-05-17 00:25:43.849127');
INSERT INTO public.voluntario_voluntaria_ong VALUES ('15808041190', 3, '2019-05-17 00:25:43.849127');
INSERT INTO public.voluntario_voluntaria_ong VALUES ('35078920437', 3, '2019-05-17 00:25:43.951289');
INSERT INTO public.voluntario_voluntaria_ong VALUES ('36812224687', 3, '2019-05-17 00:25:43.951289');
INSERT INTO public.voluntario_voluntaria_ong VALUES ('39925771438', 3, '2019-05-17 00:25:44.073073');
INSERT INTO public.voluntario_voluntaria_ong VALUES ('18883017200', 3, '2019-05-17 00:25:44.073073');
INSERT INTO public.voluntario_voluntaria_ong VALUES ('40968535373', 3, '2019-05-17 00:25:44.206345');
INSERT INTO public.voluntario_voluntaria_ong VALUES ('22042363636', 3, '2019-05-17 00:25:44.206345');
INSERT INTO public.voluntario_voluntaria_ong VALUES ('45835905239', 3, '2019-05-17 00:25:44.415413');
INSERT INTO public.voluntario_voluntaria_ong VALUES ('21984776220', 3, '2019-05-17 00:25:44.415413');
INSERT INTO public.voluntario_voluntaria_ong VALUES ('44410183993', 3, '2019-05-17 00:25:44.640878');
INSERT INTO public.voluntario_voluntaria_ong VALUES ('24507530690', 3, '2019-05-17 00:25:44.640878');
INSERT INTO public.voluntario_voluntaria_ong VALUES ('12741896242', 3, '2019-05-17 00:25:44.973068');
INSERT INTO public.voluntario_voluntaria_ong VALUES ('49390794264', 3, '2019-05-17 00:25:44.973068');
INSERT INTO public.voluntario_voluntaria_ong VALUES ('35258402567', 3, '2019-05-17 00:25:45.100934');
INSERT INTO public.voluntario_voluntaria_ong VALUES ('46879518614', 3, '2019-05-17 00:25:45.100934');
INSERT INTO public.voluntario_voluntaria_ong VALUES ('12638008109', 7, '2019-05-17 00:25:49.297982');
INSERT INTO public.voluntario_voluntaria_ong VALUES ('39925771438', 7, '2019-05-17 00:25:49.297982');
INSERT INTO public.voluntario_voluntaria_ong VALUES ('48674433818', 7, '2019-05-17 00:25:49.387074');
INSERT INTO public.voluntario_voluntaria_ong VALUES ('24410571935', 7, '2019-05-17 00:25:49.387074');
INSERT INTO public.voluntario_voluntaria_ong VALUES ('37183007160', 7, '2019-05-17 00:25:49.497651');
INSERT INTO public.voluntario_voluntaria_ong VALUES ('19315290560', 7, '2019-05-17 00:25:49.497651');
INSERT INTO public.voluntario_voluntaria_ong VALUES ('39470440513', 7, '2019-05-17 00:25:49.585304');
INSERT INTO public.voluntario_voluntaria_ong VALUES ('34277699300', 7, '2019-05-17 00:25:49.585304');
INSERT INTO public.voluntario_voluntaria_ong VALUES ('39327210257', 7, '2019-05-17 00:25:49.902285');
INSERT INTO public.voluntario_voluntaria_ong VALUES ('35078920437', 7, '2019-05-17 00:25:49.902285');
INSERT INTO public.voluntario_voluntaria_ong VALUES ('12230306633', 7, '2019-05-17 00:25:50.014304');
INSERT INTO public.voluntario_voluntaria_ong VALUES ('39981089072', 7, '2019-05-17 00:25:50.014304');
INSERT INTO public.voluntario_voluntaria_ong VALUES ('34951806509', 7, '2019-05-17 00:25:50.352526');
INSERT INTO public.voluntario_voluntaria_ong VALUES ('11319778326', 7, '2019-05-17 00:25:50.352526');
INSERT INTO public.voluntario_voluntaria_ong VALUES ('17351242993', 7, '2019-05-17 00:25:50.613192');
INSERT INTO public.voluntario_voluntaria_ong VALUES ('47893175447', 7, '2019-05-17 00:25:50.613192');
INSERT INTO public.voluntario_voluntaria_ong VALUES ('41856472055', 7, '2019-05-17 00:25:50.71345');
INSERT INTO public.voluntario_voluntaria_ong VALUES ('25554925252', 7, '2019-05-17 00:25:50.71345');
INSERT INTO public.voluntario_voluntaria_ong VALUES ('35258402567', 7, '2019-05-17 00:25:50.937229');
INSERT INTO public.voluntario_voluntaria_ong VALUES ('46879518614', 7, '2019-05-17 00:25:50.937229');
INSERT INTO public.voluntario_voluntaria_ong VALUES ('21984776220', 7, '2019-05-17 00:25:51.047678');
INSERT INTO public.voluntario_voluntaria_ong VALUES ('20932011457', 7, '2019-05-17 00:25:51.047678');


--
-- Name: doacao_codigo_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.doacao_codigo_seq', 16, true);


--
-- Name: log_beneficiario_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.log_beneficiario_id_seq', 8, true);


--
-- Name: ong_codigo_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.ong_codigo_seq', 30, true);


--
-- Name: alergias alergias_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.alergias
    ADD CONSTRAINT alergias_pk PRIMARY KEY (cpf_beneficiario, remedio);


--
-- Name: beneficiario beneficiario_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.beneficiario
    ADD CONSTRAINT beneficiario_pk PRIMARY KEY (cpf_pessoa);


--
-- Name: beneficiario_possui_responsavel beneficiario_possui_responsavel_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.beneficiario_possui_responsavel
    ADD CONSTRAINT beneficiario_possui_responsavel_pk PRIMARY KEY (cpf_pessoa, cpf_beneficiario);


--
-- Name: doacao doacao_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.doacao
    ADD CONSTRAINT doacao_pk PRIMARY KEY (cpf_pessoa, codigo);


--
-- Name: log_beneficiario log_beneficiario_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.log_beneficiario
    ADD CONSTRAINT log_beneficiario_pk PRIMARY KEY (id);


--
-- Name: ong ong_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ong
    ADD CONSTRAINT ong_pk PRIMARY KEY (codigo);


--
-- Name: pessoa pessoa_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.pessoa
    ADD CONSTRAINT pessoa_pk PRIMARY KEY (cpf);


--
-- Name: voluntario voluntario_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.voluntario
    ADD CONSTRAINT voluntario_pk PRIMARY KEY (cpf_pessoa);


--
-- Name: voluntario_voluntaria_ong voluntario_voluntaria_ong_pk; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.voluntario_voluntaria_ong
    ADD CONSTRAINT voluntario_voluntaria_ong_pk PRIMARY KEY (cpf_voluntario, codigo_ong);


--
-- Name: beneficiario_cpf_pessoa_uindex; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX beneficiario_cpf_pessoa_uindex ON public.beneficiario USING btree (cpf_pessoa);


--
-- Name: doacao_codigo_uindex; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX doacao_codigo_uindex ON public.doacao USING btree (codigo);


--
-- Name: log_beneficiario_id_uindex; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX log_beneficiario_id_uindex ON public.log_beneficiario USING btree (id);


--
-- Name: ong_codigo_uindex; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ong_codigo_uindex ON public.ong USING btree (codigo);


--
-- Name: ong_cpf_voluntario_responsavel_uindex; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX ong_cpf_voluntario_responsavel_uindex ON public.ong USING btree (cpf_voluntario_responsavel);


--
-- Name: pessoa_cpf_uindex; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX pessoa_cpf_uindex ON public.pessoa USING btree (cpf);


--
-- Name: voluntario_cpf_pessoa_uindex; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX voluntario_cpf_pessoa_uindex ON public.voluntario USING btree (cpf_pessoa);


--
-- Name: beneficiario_participa_ong entrada_beneficiario; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER entrada_beneficiario AFTER INSERT ON public.beneficiario_participa_ong FOR EACH ROW EXECUTE PROCEDURE public.log_entrada_beneficiario();


--
-- Name: beneficiario_participa_ong saida_beneficiario; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER saida_beneficiario BEFORE DELETE ON public.beneficiario_participa_ong FOR EACH ROW EXECUTE PROCEDURE public.log_saida_beneficiario();


--
-- Name: alergias alergias_beneficiario_cpf_pessoa_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.alergias
    ADD CONSTRAINT alergias_beneficiario_cpf_pessoa_fk FOREIGN KEY (cpf_beneficiario) REFERENCES public.beneficiario(cpf_pessoa) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: beneficiario_participa_ong beneficiario_participa_ong_beneficiario_cpf_pessoa_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.beneficiario_participa_ong
    ADD CONSTRAINT beneficiario_participa_ong_beneficiario_cpf_pessoa_fk FOREIGN KEY (cpf_beneficiario) REFERENCES public.beneficiario(cpf_pessoa) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: beneficiario_participa_ong beneficiario_participa_ong_ong_codigo_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.beneficiario_participa_ong
    ADD CONSTRAINT beneficiario_participa_ong_ong_codigo_fk FOREIGN KEY (codigo_ong) REFERENCES public.ong(codigo) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: beneficiario beneficiario_pessoa_cpf_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.beneficiario
    ADD CONSTRAINT beneficiario_pessoa_cpf_fk FOREIGN KEY (cpf_pessoa) REFERENCES public.pessoa(cpf) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: beneficiario_possui_responsavel beneficiario_possui_responsavel_beneficiario_cpf_pessoa_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.beneficiario_possui_responsavel
    ADD CONSTRAINT beneficiario_possui_responsavel_beneficiario_cpf_pessoa_fk FOREIGN KEY (cpf_beneficiario) REFERENCES public.beneficiario(cpf_pessoa) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: beneficiario_possui_responsavel beneficiario_possui_responsavel_pessoa_cpf_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.beneficiario_possui_responsavel
    ADD CONSTRAINT beneficiario_possui_responsavel_pessoa_cpf_fk FOREIGN KEY (cpf_pessoa) REFERENCES public.pessoa(cpf) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: doacao doacao_ong_codigo_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.doacao
    ADD CONSTRAINT doacao_ong_codigo_fk FOREIGN KEY (codigo_ong) REFERENCES public.ong(codigo) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: doacao doacao_pessoa_cpf_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.doacao
    ADD CONSTRAINT doacao_pessoa_cpf_fk FOREIGN KEY (cpf_pessoa) REFERENCES public.pessoa(cpf) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: log_beneficiario log_beneficiario_beneficiario_cpf_pessoa_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.log_beneficiario
    ADD CONSTRAINT log_beneficiario_beneficiario_cpf_pessoa_fk FOREIGN KEY (cpf_beneficiario) REFERENCES public.beneficiario(cpf_pessoa) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: ong ong_voluntario_cpf_pessoa_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ong
    ADD CONSTRAINT ong_voluntario_cpf_pessoa_fk FOREIGN KEY (cpf_voluntario_responsavel) REFERENCES public.voluntario(cpf_pessoa) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: voluntario voluntario_pessoa_cpf_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.voluntario
    ADD CONSTRAINT voluntario_pessoa_cpf_fk FOREIGN KEY (cpf_pessoa) REFERENCES public.pessoa(cpf) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: voluntario_voluntaria_ong voluntario_voluntaria_ong_ong_codigo_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.voluntario_voluntaria_ong
    ADD CONSTRAINT voluntario_voluntaria_ong_ong_codigo_fk FOREIGN KEY (codigo_ong) REFERENCES public.ong(codigo) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: voluntario_voluntaria_ong voluntario_voluntaria_ong_voluntario_cpf_pessoa_fk; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.voluntario_voluntaria_ong
    ADD CONSTRAINT voluntario_voluntaria_ong_voluntario_cpf_pessoa_fk FOREIGN KEY (cpf_voluntario) REFERENCES public.voluntario(cpf_pessoa) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

