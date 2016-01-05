//
//  DetailViewController.swift
//  libros_maestro-detalle
//
//  Created by César Méndez on 29/12/15.
//  Copyright © 2015 César Méndez. All rights reserved.
//

import UIKit
import CoreData

class DetailViewController: UIViewController, UITextFieldDelegate {

    
    @IBOutlet weak var isbnEtiqueta: UILabel!
    @IBOutlet weak var etiqueta: UILabel!
    @IBOutlet weak var isbn: UITextField!
    @IBOutlet weak var portada: UIImageView!
    @IBOutlet weak var tituloDeLibro: UILabel!
    @IBOutlet weak var autorLibro: UILabel!
    
    var isbnBuscar : String = ""
    var tipoDetalle : Int = 0
    var contexto : NSManagedObjectContext? = nil
    var detailItem: AnyObject? {
        didSet {
            // Update the view.
            self.configureView()
        }
    }

    func configureView() {
        // Update the user interface for the detail item.
        /* if let detail = self.detailItem {
            if let label = self.detailDescriptionLabel {
                label.text = detail.valueForKey("timeStamp")!.description
            }

        }*/
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.isbn.delegate = self
        tituloDeLibro.text = nil
        autorLibro.text = nil
        
        self.configureView()
        self.contexto = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
        if tipoDetalle == 1 {
      
            llenarDetalle(isbnBuscar)

            
            
        }
        else
        {
             self.etiqueta.hidden = false
            self.isbnEtiqueta.hidden = true
            self.isbn.hidden = false
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        
        self.view.endEditing(true)
        
        return true
        
    }
    
    func textFieldDidBeginEditing(textField: UITextField) {
        isbn.becomeFirstResponder()
        
        self.tituloDeLibro.text = ""
        self.autorLibro.text = ""
        self.portada.image = nil
    }
    

    func textFieldShouldClear(textField: UITextField) -> Bool {
        
        self.tituloDeLibro.text = ""
        self.autorLibro.text = ""
        self.portada.image = nil
        isbn.becomeFirstResponder()
        return true
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        isbn.resignFirstResponder()
    }
    
  
   
    
    func textFieldShouldEndEditing(textField: UITextField) -> Bool {
        if self.isbn.text! != "" {
            if existeLibro(self.isbn.text!) == false
            {
                busqueda(self.isbn.text!)
            }
        }
        return true
    }
    
    
    func busqueda( varISBN : String?)
    {
        if varISBN! != "" {
            
            
            
            let urls = "https://openlibrary.org/api/books?jscmd=data&format=json&bibkeys=ISBN:" + varISBN!
            let url = NSURL(string: urls)
            
            
            
            let config = NSURLSessionConfiguration.defaultSessionConfiguration()
            let sesion = NSURLSession(configuration: config, delegate:nil, delegateQueue:NSOperationQueue.mainQueue())
            let req = NSURLRequest(URL: url!)
            
            
            let dataTask = sesion.dataTaskWithRequest(req) {
                
                (data:NSData?, response:NSURLResponse?, error:NSError?) -> Void in
                
                if error != nil {
                    
                    self.isbn.text = ""
                    
                    
                    
                    let alerta = UIAlertController(title: "Advertencia", message:  "No hay conexión a internet, Intente de nuevo más tarde", preferredStyle: .Alert)
                    let defaultAction = UIAlertAction(title: "Ok", style: .Default, handler: nil)
                    alerta.addAction(defaultAction)
                    self.presentViewController(alerta, animated: true, completion: nil)
                    
                    
                } else {
                    
                    
                    
                    let datos = NSData(contentsOfURL: url!)
                    
                    let raiz = "ISBN:" + varISBN!
                    
                    do {
                        let json = try NSJSONSerialization.JSONObjectWithData(datos!,options: NSJSONReadingOptions.MutableLeaves)
                        let dico1 = json as! NSDictionary
                        if dico1.count != 0 {
                            let dico2 = dico1[raiz] as! NSDictionary
                            
                            var nombreL : String? = ""
                            nombreL! = nombreL! + String ( dico2["title"] as! NSString as String)
                            self.tituloDeLibro.text = "Titulo: " + nombreL!
                            if self.tipoDetalle != 1 {
                                arregloLibros.append([nombreL!,varISBN!])
                            }
                            var nombreA : String? = ""
                            if let listaAutores = json[raiz]!!["authors"] as? NSArray {
                                let autorDeLista = listaAutores[0] as! NSDictionary
                                
                                nombreA = (autorDeLista["name"]! as! String)
                                
                                if listaAutores.count > 1 {
                                    for var i = 1; i < listaAutores.count; i++ {
                                        nombreA! = nombreA! + ", " + (listaAutores[i]["name"]! as! String)
                                    }
                                }
                                
                                self.autorLibro.text = "Autor(es): " + nombreA!
                                
                            } else {
                                self.autorLibro.text = "Autor(es): Sin autor"
                            }
                            
                            
                            let cover = "http://covers.openlibrary.org/b/isbn/" + varISBN! + "-M.jpg"
                            
                                      //--------------
                            guard
                                let url = NSURL(string: cover)
                                else {return}
                            
                            NSURLSession.sharedSession().dataTaskWithURL(url, completionHandler: { (data, _, error) -> Void in
                                guard
                                    let data = data where error == nil,
                                    let image  = UIImage(data: data)
                                    else { return }
                                dispatch_async(dispatch_get_main_queue()) { () -> Void in
                                    self.portada.image = image
                                    
                                    //---------
                                    let nuevoRegistro = NSEntityDescription.insertNewObjectForEntityForName("Libros", inManagedObjectContext: self.contexto!)

                                    
                                    nuevoRegistro.setValue(varISBN!, forKey: "isbn")
                                    nuevoRegistro.setValue(nombreL!, forKey: "titulo")
                                    nuevoRegistro.setValue(nombreA!, forKey: "autores")
                                    //if self.portada.image! != nil {
                                    nuevoRegistro.setValue(UIImagePNGRepresentation(self.portada.image!), forKey: "caratula")
                                    
                                    
                                    //}
                                    do {
                                        try self.contexto!.save()
                                    }catch{
                                        abort()
                                    }
                                    //---------
                                }
                            }).resume()
                            
                            //--------------
                            
                            
                            
                        }
                        else
                        {
                            
                            let alerta = UIAlertController(title: "Aviso", message:  "No se localizó el número ISBN", preferredStyle: .Alert)
                            let defaultAction = UIAlertAction(title: "Ok", style: .Default, handler: nil)
                            alerta.addAction(defaultAction)
                            self.presentViewController(alerta, animated: true, completion: nil)
                        }
                    } catch _ as NSError {
                        let alerta = UIAlertController(title: "Advertencia", message:  "Imposible cargar el archivo JSON", preferredStyle: .Alert)
                        let defaultAction = UIAlertAction(title: "Ok", style: .Default, handler: nil)
                        alerta.addAction(defaultAction)
                        self.presentViewController(alerta, animated: true, completion: nil)
                    }
                    
                    
                    
                }
                
                
            }
            
            dataTask.resume()
            
            isbn.resignFirstResponder()
        }
    }
    
    
    func existeLibro(varISBN : String?) -> Bool {
        let entLibro = NSEntityDescription.entityForName("Libros", inManagedObjectContext: self.contexto!)
        let pet = entLibro?.managedObjectModel.fetchRequestFromTemplateWithName("petDetalle", substitutionVariables: ["isbn": varISBN!])
        do {
            let entDetalle = try self.contexto!.executeFetchRequest(pet!)
            if entDetalle.count > 0 {
                llenarDetalle(varISBN!)
                return true
            }else {
                return false
            }
        }catch{
            abort()
        }
    }
    
    

    func llenarDetalle(varISBN : String?) {
        
        
        let entLibro = NSEntityDescription.entityForName("Libros", inManagedObjectContext: self.contexto!)
        let petDetalle = entLibro?.managedObjectModel.fetchRequestFromTemplateWithName("petDetalle", substitutionVariables: ["isbn" : varISBN!])
        
        do {
            let entDetalle = try self.contexto!.executeFetchRequest(petDetalle!)
            if (entDetalle.count > 0){
                
                self.isbn.hidden = true
                self.etiqueta.hidden = true
                self.isbnEtiqueta.hidden = false
                self.isbnEtiqueta.text = "ISBN: " + varISBN!
                
                for det in entDetalle {
                    
                    let tmpTitulo : String? = (det.valueForKey("titulo") as! String)
                    let tmpAutores : String? = (det.valueForKey("autores") as! String)
                    
                    tituloDeLibro.text = "Titulo: " + tmpTitulo!
                   
                    autorLibro.text = "Autor(es): " + tmpAutores!
                  
                    if det.valueForKey("caratula") != nil {
                        self.portada.image =  UIImage(data: (det.valueForKey("caratula") as! NSData))
                    }
                   
                }
                
            }
            
        }
        catch{
            
        }
    }

    

    

}

