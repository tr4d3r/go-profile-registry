package main

import (
	"crypto/sha256"
	"encoding/json"
	"flag"
	"fmt"
	"io/fs"
	"log"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"time"
)

// Module represents a go-profile module
type Module struct {
	Name         string        `json:"name"`
	Version      string        `json:"version"`
	Description  string        `json:"description"`
	Category     string        `json:"category"`
	Author       string        `json:"author,omitempty"`
	License      string        `json:"license,omitempty"`
	Homepage     string        `json:"homepage,omitempty"`
	Repository   *Repository   `json:"repository,omitempty"`
	Platforms    []string      `json:"platforms"`
	Shells       []string      `json:"shells"`
	Dependencies *Dependencies `json:"dependencies,omitempty"`
	Environment  []Environment `json:"environment,omitempty"`
	Aliases      []Alias       `json:"aliases,omitempty"`
	Functions    []Function    `json:"functions,omitempty"`
	Path         []PathEntry   `json:"path,omitempty"`
	Files        []File        `json:"files,omitempty"`
	Checks       []Check       `json:"checks,omitempty"`
}

type Repository struct {
	Type string `json:"type"`
	URL  string `json:"url"`
}

type Dependencies struct {
	Modules  []string `json:"modules,omitempty"`
	Commands []string `json:"commands,omitempty"`
	Optional []string `json:"optional,omitempty"`
}

type Environment struct {
	Name        string `json:"name"`
	Value       string `json:"value"`
	Export      bool   `json:"export,omitempty"`
	Description string `json:"description,omitempty"`
}

type Alias struct {
	Name        string `json:"name"`
	Command     string `json:"command"`
	Description string `json:"description,omitempty"`
}

type Function struct {
	Name        string   `json:"name"`
	Description string   `json:"description,omitempty"`
	Commands    []string `json:"commands"`
	Parameters  []string `json:"parameters,omitempty"`
}

type PathEntry struct {
	Directory string `json:"directory"`
	Prepend   bool   `json:"prepend,omitempty"`
}

type File struct {
	Path        string `json:"path"`
	Content     string `json:"content,omitempty"`
	Source      bool   `json:"source,omitempty"`
	Execute     bool   `json:"execute,omitempty"`
	Mode        string `json:"mode,omitempty"`
	Description string `json:"description,omitempty"`
}

type Check struct {
	Name        string   `json:"name"`
	Description string   `json:"description,omitempty"`
	Type        string   `json:"type"`
	Command     string   `json:"command,omitempty"`
	Args        []string `json:"args,omitempty"`
	Path        string   `json:"path,omitempty"`
	Variable    string   `json:"variable,omitempty"`
	Required    bool     `json:"required,omitempty"`
	OnSuccess   []string `json:"on_success,omitempty"`
	OnFailure   []string `json:"on_failure,omitempty"`
}

// Registry structures
type RegistryIndex struct {
	Version     string                    `json:"version"`
	LastUpdated string                    `json:"last_updated"`
	BaseURL     string                    `json:"base_url"`
	Categories  []string                  `json:"categories"`
	Modules     map[string]ModuleMetadata `json:"modules"`
	Statistics  Statistics                `json:"statistics"`
}

type ModuleMetadata struct {
	Latest      string   `json:"latest"`
	Versions    []string `json:"versions"`
	Category    string   `json:"category"`
	Description string   `json:"description"`
	URL         string   `json:"url"`
	Checksum    string   `json:"checksum"`
	Size        int64    `json:"size"`
	Author      string   `json:"author,omitempty"`
	License     string   `json:"license,omitempty"`
	Tags        []string `json:"tags,omitempty"`
}

type Statistics struct {
	TotalModules    int            `json:"total_modules"`
	TotalDownloads  int            `json:"total_downloads"`
	CategoriesCount map[string]int `json:"categories_count"`
}

type CategoryDefinition struct {
	Name        string   `json:"name"`
	Description string   `json:"description"`
	Icon        string   `json:"icon"`
	Color       string   `json:"color"`
	Priority    int      `json:"priority"`
	Modules     []string `json:"modules"`
}

type Categories struct {
	Version    string                        `json:"version"`
	Categories map[string]CategoryDefinition `json:"categories"`
	Metadata   CategoryMetadata              `json:"metadata"`
}

type CategoryMetadata struct {
	TotalCategories  int    `json:"total_categories"`
	ActiveCategories int    `json:"active_categories"`
	LastUpdated      string `json:"last_updated"`
}

type VersionMetadata struct {
	Module          string            `json:"module"`
	Version         string            `json:"version"`
	ReleaseDate     string            `json:"release_date"`
	Category        string            `json:"category"`
	Changelog       []ChangelogEntry  `json:"changelog"`
	BreakingChanges []string          `json:"breaking_changes"`
	Dependencies    *Dependencies     `json:"dependencies,omitempty"`
	Compatibility   CompatibilityInfo `json:"compatibility"`
	FileInfo        FileInfo          `json:"file_info"`
	Author          string            `json:"author,omitempty"`
	License         string            `json:"license,omitempty"`
	Tags            []string          `json:"tags,omitempty"`
}

type ChangelogEntry struct {
	Type        string `json:"type"`
	Description string `json:"description"`
}

type CompatibilityInfo struct {
	Platforms []string               `json:"platforms"`
	Shells    []string               `json:"shells"`
	Extra     map[string]interface{} `json:",inline,omitempty"`
}

type FileInfo struct {
	URL      string `json:"url"`
	Checksum string `json:"checksum"`
	Size     int64  `json:"size"`
	MimeType string `json:"mime_type"`
}

func main() {
	var (
		modulesDir  = flag.String("modules-dir", "./modules", "Modules directory")
		registryDir = flag.String("registry-dir", "./registry", "Registry output directory")
		baseURL     = flag.String("base-url", "https://registry.go-profile.dev", "Base URL for registry")
	)
	flag.Parse()

	builder := &RegistryBuilder{
		ModulesDir:  *modulesDir,
		RegistryDir: *registryDir,
		BaseURL:     *baseURL,
	}

	if err := builder.Build(); err != nil {
		log.Fatal(err)
	}

	fmt.Println("✅ Registry generation completed successfully!")
}

type RegistryBuilder struct {
	ModulesDir  string
	RegistryDir string
	BaseURL     string
}

func (b *RegistryBuilder) Build() error {
	fmt.Println("🔍 Scanning modules directory...")
	modules, err := b.scanModules()
	if err != nil {
		return fmt.Errorf("scanning modules: %w", err)
	}

	fmt.Printf("📦 Found %d modules\n", len(modules))

	// Generate index.json
	fmt.Println("📋 Generating registry index...")
	if err := b.generateIndex(modules); err != nil {
		return fmt.Errorf("generating index: %w", err)
	}

	// Generate categories.json
	fmt.Println("🏷️  Generating category definitions...")
	if err := b.generateCategories(modules); err != nil {
		return fmt.Errorf("generating categories: %w", err)
	}

	// Generate version metadata
	fmt.Println("📄 Generating version metadata...")
	if err := b.generateVersions(modules); err != nil {
		return fmt.Errorf("generating versions: %w", err)
	}

	return nil
}

func (b *RegistryBuilder) scanModules() (map[string]*Module, error) {
	modules := make(map[string]*Module)

	err := filepath.WalkDir(b.ModulesDir, func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}

		if !d.IsDir() && strings.HasSuffix(path, ".json") {
			module, err := b.loadModule(path)
			if err != nil {
				return fmt.Errorf("loading %s: %w", path, err)
			}
			if module.Name == "" {
				// Use filename as module name if not specified
				module.Name = strings.TrimSuffix(d.Name(), ".json")
			}
			modules[module.Name] = module
		}

		return nil
	})

	return modules, err
}

func (b *RegistryBuilder) loadModule(path string) (*Module, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}

	var module Module
	if err := json.Unmarshal(data, &module); err != nil {
		return nil, err
	}

	return &module, nil
}

func (b *RegistryBuilder) generateIndex(modules map[string]*Module) error {
	index := RegistryIndex{
		Version:     "1.0.0",
		LastUpdated: time.Now().UTC().Format(time.RFC3339),
		BaseURL:     b.BaseURL,
		Categories:  b.extractCategories(modules),
		Modules:     make(map[string]ModuleMetadata),
		Statistics: Statistics{
			TotalModules:    len(modules),
			TotalDownloads:  0,
			CategoriesCount: make(map[string]int),
		},
	}

	for name, module := range modules {
		// Calculate relative path from modules directory
		relativePath := b.getModuleRelativePath(module)
		fullPath := filepath.Join(b.ModulesDir, relativePath)

		checksum, size, err := b.calculateChecksum(fullPath)
		if err != nil {
			return fmt.Errorf("calculating checksum for %s: %w", name, err)
		}

		// Generate tags from module properties
		tags := b.generateTags(module)

		index.Modules[name] = ModuleMetadata{
			Latest:      module.Version,
			Versions:    []string{module.Version},
			Category:    module.Category,
			Description: module.Description,
			URL:         "modules/" + relativePath,
			Checksum:    checksum,
			Size:        size,
			Author:      module.Author,
			License:     module.License,
			Tags:        tags,
		}

		// Update statistics
		index.Statistics.CategoriesCount[module.Category]++
	}

	return b.writeJSON(filepath.Join(b.RegistryDir, "index.json"), index)
}

func (b *RegistryBuilder) getModuleRelativePath(module *Module) string {
	if module.Category != "" {
		return fmt.Sprintf("%s/%s.json", module.Category, module.Name)
	}
	return fmt.Sprintf("%s.json", module.Name)
}

func (b *RegistryBuilder) calculateChecksum(path string) (string, int64, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return "", 0, err
	}

	hash := fmt.Sprintf("sha256:%x", sha256.Sum256(data))
	return hash, int64(len(data)), nil
}

func (b *RegistryBuilder) extractCategories(modules map[string]*Module) []string {
	categorySet := make(map[string]bool)
	for _, module := range modules {
		if module.Category != "" {
			categorySet[module.Category] = true
		}
	}

	var categories []string
	for category := range categorySet {
		categories = append(categories, category)
	}

	sort.Strings(categories)
	return categories
}

func (b *RegistryBuilder) generateTags(module *Module) []string {
	tagSet := make(map[string]bool)

	// Add category as tag
	if module.Category != "" {
		tagSet[module.Category] = true
	}

	// Add module name as tag
	tagSet[module.Name] = true

	// Add platform tags
	for _, platform := range module.Platforms {
		tagSet[platform] = true
	}

	// Add shell tags
	for _, shell := range module.Shells {
		tagSet[shell] = true
	}

	// Add dependency tags
	if module.Dependencies != nil {
		for _, cmd := range module.Dependencies.Commands {
			tagSet[cmd] = true
		}
	}

	var tags []string
	for tag := range tagSet {
		tags = append(tags, tag)
	}

	sort.Strings(tags)
	return tags
}

func (b *RegistryBuilder) generateCategories(modules map[string]*Module) error {
	categoryDefs := map[string]CategoryDefinition{
		"development": {
			Name:        "Development Tools",
			Description: "Programming languages, version control, and development utilities",
			Icon:        "🛠️",
			Color:       "#007ACC",
			Priority:    1,
			Modules:     []string{},
		},
		"ai-tools": {
			Name:        "AI Tools",
			Description: "Artificial Intelligence and Machine Learning development tools",
			Icon:        "🤖",
			Color:       "#FF6B35",
			Priority:    2,
			Modules:     []string{},
		},
		"enterprise": {
			Name:        "Enterprise",
			Description: "Security, compliance, and enterprise-specific configurations",
			Icon:        "🏢",
			Color:       "#6F42C1",
			Priority:    3,
			Modules:     []string{},
		},
		"devops": {
			Name:        "DevOps",
			Description: "Infrastructure, deployment, and operations tools",
			Icon:        "⚙️",
			Color:       "#28A745",
			Priority:    4,
			Modules:     []string{},
		},
		"platform": {
			Name:        "Platform",
			Description: "Operating system and platform-specific configurations",
			Icon:        "💻",
			Color:       "#6C757D",
			Priority:    5,
			Modules:     []string{},
		},
	}

	// Populate modules for each category
	for _, module := range modules {
		if def, exists := categoryDefs[module.Category]; exists {
			def.Modules = append(def.Modules, module.Name)
			categoryDefs[module.Category] = def
		}
	}

	// Sort modules within each category
	for category, def := range categoryDefs {
		sort.Strings(def.Modules)
		categoryDefs[category] = def
	}

	activeCategories := 0
	for _, def := range categoryDefs {
		if len(def.Modules) > 0 {
			activeCategories++
		}
	}

	categories := Categories{
		Version:    "1.0.0",
		Categories: categoryDefs,
		Metadata: CategoryMetadata{
			TotalCategories:  len(categoryDefs),
			ActiveCategories: activeCategories,
			LastUpdated:      time.Now().UTC().Format(time.RFC3339),
		},
	}

	return b.writeJSON(filepath.Join(b.RegistryDir, "categories.json"), categories)
}

func (b *RegistryBuilder) generateVersions(modules map[string]*Module) error {
	versionsDir := filepath.Join(b.RegistryDir, "versions")

	for _, module := range modules {
		// Create category directory
		categoryDir := filepath.Join(versionsDir, module.Category)
		if err := os.MkdirAll(categoryDir, 0755); err != nil {
			return fmt.Errorf("creating category directory %s: %w", categoryDir, err)
		}

		// Generate version metadata
		versionMeta := VersionMetadata{
			Module:      module.Name,
			Version:     module.Version,
			ReleaseDate: time.Now().UTC().Format(time.RFC3339),
			Category:    module.Category,
			Changelog: []ChangelogEntry{
				{
					Type:        "added",
					Description: fmt.Sprintf("Initial %s module", module.Name),
				},
			},
			BreakingChanges: []string{},
			Dependencies:    module.Dependencies,
			Compatibility: CompatibilityInfo{
				Platforms: module.Platforms,
				Shells:    module.Shells,
			},
			Author:  module.Author,
			License: module.License,
			Tags:    b.generateTags(module),
		}

		// Add file info
		relativePath := b.getModuleRelativePath(module)
		fullPath := filepath.Join(b.ModulesDir, relativePath)
		checksum, size, err := b.calculateChecksum(fullPath)
		if err != nil {
			return fmt.Errorf("calculating checksum for version metadata: %w", err)
		}

		versionMeta.FileInfo = FileInfo{
			URL:      "modules/" + relativePath,
			Checksum: checksum,
			Size:     size,
			MimeType: "application/json",
		}

		// Write version metadata file
		versionFile := filepath.Join(categoryDir, fmt.Sprintf("%s-v%s.json", module.Name, module.Version))
		if err := b.writeJSON(versionFile, versionMeta); err != nil {
			return fmt.Errorf("writing version metadata: %w", err)
		}
	}

	return nil
}

func (b *RegistryBuilder) writeJSON(path string, data interface{}) error {
	// Ensure directory exists
	if err := os.MkdirAll(filepath.Dir(path), 0755); err != nil {
		return err
	}

	jsonData, err := json.MarshalIndent(data, "", "  ")
	if err != nil {
		return err
	}

	return os.WriteFile(path, jsonData, 0644)
}
