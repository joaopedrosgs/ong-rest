package main

import (
	"projeto_bd/controller"

	"github.com/labstack/echo"
	"github.com/labstack/echo/middleware"
)

func main() {
	pessoaController := controller.NewPessoaController()
	if pessoaController == nil {
		println("Falha ao criar PessoaController")
		return
	}
	voluntarioController := controller.NewVoluntarioController()
	if voluntarioController == nil {
		println("Falha ao criar VoluntarioController")
		return
	}
	doacaoController := controller.NewDoacaoController()
	if doacaoController == nil {
		println("Falha ao criar DoacaoController")
		return
	}
	logController := controller.NewLogController()
	if logController == nil {
		println("Falha ao criar LogController")
		return
	}
	alergiaController := controller.NewAlergiaController()
	if alergiaController == nil {
		println("Falha ao criar AlergiaController")
		return
	}
	ongController := controller.NewOngController()
	if ongController == nil {
		println("Falha ao criar OngController")
		return
	}
	beneficiarioController := controller.NewBeneficiarioController()
	if beneficiarioController == nil {
		println("Falha ao criar BeneficiarioController")
		return
	}
	e := echo.New()

	// Middleware
	e.Use(middleware.Logger())
	e.Use(middleware.Recover())

	// Routes de pessoas
	e.POST("/pessoa", pessoaController.Post)
	e.GET("/pessoa/", pessoaController.Get)
	e.GET("/pessoa/:cpf", pessoaController.Get)
	e.PUT("/pessoa/:cpf", pessoaController.Put)
	e.DELETE("/pessoa/:cpf", pessoaController.Delete)

	// Routes de beneficiario
	e.POST("/beneficiario", beneficiarioController.Post)
	e.GET("/beneficiario/", beneficiarioController.Get)
	e.GET("/beneficiario/:cpf", beneficiarioController.Get)
	e.PUT("/beneficiario/:cpf", beneficiarioController.Put)
	e.DELETE("/beneficiario/:cpf", beneficiarioController.Delete)

	// Routes de doacao
	e.POST("/doacao", doacaoController.Post)
	e.GET("/doacao/", doacaoController.Get)
	e.GET("/doacao/:codigo", doacaoController.Get)
	e.PUT("/doacao/:codigo", doacaoController.Put)
	e.DELETE("/doacao/:codigo", doacaoController.Delete)

	// Routes de log
	e.GET("/log/", logController.Get)

	// Routes de voluntarios
	e.POST("/voluntario", voluntarioController.Post)
	e.GET("/voluntario/:cpf", voluntarioController.Get)
	e.GET("/voluntario/", voluntarioController.Get)
	e.PUT("/voluntario/:cpf", voluntarioController.Put)
	e.DELETE("/voluntario/:cpf", voluntarioController.Delete)

	// Routes de ongs
	e.POST("/ong", ongController.Post)
	e.GET("/ong/:codigo", ongController.Get)
	e.GET("/ong/", ongController.Get)
	e.PUT("/ong/:codigo", ongController.Put)
	e.DELETE("/ong/:codigo", ongController.Delete)

	// Routes de alergias
	e.POST("/alergia", alergiaController.Post)
	e.GET("/alergia/:cpf", alergiaController.Get)
	e.GET("/alergia/", alergiaController.Get)
	e.PUT("/alergia/:cpf", alergiaController.Put)
	e.DELETE("/alergia/:cpf", alergiaController.Delete)
	// Start server
	e.Logger.Fatal(e.Start(":1323"))
}
